import SwiftUI
import AppKit

// Create and run the app
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var clipboardManager: ClipboardManager?
    var hotkeyManager: HotkeyManager?
    var clipboardPopup: ClipboardPopup?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App starting...")
        
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        
        // Delay clipboard manager setup to avoid initialization issues
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setupClipboardManager()
        }
        
        // Setup hotkey and popup even later to ensure everything is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.setupHotkeyManager()
            self.setupClipboardPopup()
        }
    }
    
    private func setupStatusItem() {
        print("Setting up status item...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Clipboard History")
        }
        updateMenu()
    }
    
    private func setupClipboardManager() {
        print("Setting up clipboard manager...")
        clipboardManager = ClipboardManager()
        clipboardManager?.delegate = self
        clipboardManager?.startMonitoring()
    }
    
    private func setupHotkeyManager() {
        print("Setting up hotkey manager...")
        hotkeyManager = HotkeyManager()
        hotkeyManager?.delegate = self
        hotkeyManager?.registerHotkey()
    }
    
    private func setupClipboardPopup() {
        print("Setting up clipboard popup...")
        clipboardPopup = ClipboardPopup()
        clipboardPopup?.delegate = self
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // Add info about hotkey (only if hotkey manager is set up)
        if hotkeyManager != nil {
            let hotkeyInfo = NSMenuItem(title: "Press ⌘⇧V for quick access", action: nil, keyEquivalent: "")
            hotkeyInfo.isEnabled = false
            menu.addItem(hotkeyInfo)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Add clipboard history items
        let history = clipboardManager?.getHistory() ?? []
        print("Updating menu with \(history.count) items")
        
        if history.isEmpty {
            let emptyItem = NSMenuItem(title: "No clipboard history", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (index, item) in history.enumerated() {
                let menuTitle = item.truncated(to: 50)
                let menuItem = NSMenuItem(title: menuTitle, action: #selector(selectClipboardItem(_:)), keyEquivalent: "")
                menuItem.tag = index
                menuItem.target = self
                menu.addItem(menuItem)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Add clear history option
        if !history.isEmpty {
            let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
            clearItem.target = self
            menu.addItem(clearItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Add quit option
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func selectClipboardItem(_ sender: NSMenuItem) {
        guard let history = clipboardManager?.getHistory(),
              sender.tag >= 0,
              sender.tag < history.count else { 
            print("Invalid menu item selection")
            return 
        }
        
        let selectedItem = history[sender.tag]
        print("Selected item: \(selectedItem)")
        clipboardManager?.copyToClipboard(selectedItem)
    }
    
    @objc func clearHistory() {
        print("Clearing history")
        clipboardManager?.clearHistory()
        updateMenu()
    }

    @objc func quit() {
        print("Quitting app")
        hotkeyManager?.unregisterHotkey()
        clipboardManager?.stopMonitoring()
        clipboardPopup?.hide()
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - ClipboardManagerDelegate
extension AppDelegate: ClipboardManagerDelegate {
    func clipboardDidChange() {
        print("Clipboard changed")
        DispatchQueue.main.async { [weak self] in
            self?.updateMenu()
        }
    }
}

// MARK: - HotkeyManagerDelegate
extension AppDelegate: HotkeyManagerDelegate {
    func hotkeyPressed() {
        print("Hotkey pressed!")
        DispatchQueue.main.async { [weak self] in
            guard let history = self?.clipboardManager?.getHistory() else { 
                print("No history available")
                return 
            }
            print("Showing popup with \(history.count) items")
            self?.clipboardPopup?.show(with: history)
        }
    }
}

// MARK: - ClipboardPopupDelegate  
extension AppDelegate: ClipboardPopupDelegate {
    func popupDidSelectItem(_ item: String) {
        print("Popup item selected: \(item)")
        // First copy to clipboard
        clipboardManager?.copyToClipboard(item)
        
        // Then simulate paste with a delay to ensure clipboard is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        print("Simulating paste...")
        // Create CGEvent for Cmd+V
        guard let source = CGEventSource(stateID: .combinedSessionState) else { 
            print("Failed to create event source")
            return 
        }
        
        // Create key down and up events for V key (keyCode 9)
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { 
            print("Failed to create key events")
            return 
        }
        
        // Add Command modifier
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand
        
        // Post the events
        keyDownEvent.post(tap: .cgSessionEventTap)
        keyUpEvent.post(tap: .cgSessionEventTap)
        print("Paste events sent")
    }
}

extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        } else {
            return self
        }
    }
} 