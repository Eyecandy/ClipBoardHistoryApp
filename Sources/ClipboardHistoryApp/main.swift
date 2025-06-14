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
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Clipboard History")
        }
        updateMenu()
    }
    
    private func setupClipboardManager() {
        clipboardManager = ClipboardManager()
        clipboardManager?.delegate = self
        clipboardManager?.startMonitoring()
    }
    
    private func setupHotkeyManager() {
        hotkeyManager = HotkeyManager()
        hotkeyManager?.delegate = self
        hotkeyManager?.registerHotkey()
    }
    
    private func setupClipboardPopup() {
        clipboardPopup = ClipboardPopup()
        clipboardPopup?.delegate = self
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // Add info about hotkey (only if hotkey manager is set up)
        if hotkeyManager != nil {
            let hotkeyInfo = NSMenuItem(title: "Press ⌘⇧C for quick access", action: nil, keyEquivalent: "")
            hotkeyInfo.isEnabled = false
            menu.addItem(hotkeyInfo)
            
            let copyInfo = NSMenuItem(title: "Click items to copy, then paste with ⌘V", action: nil, keyEquivalent: "")
            copyInfo.isEnabled = false
            menu.addItem(copyInfo)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Add clipboard history items
        let history = clipboardManager?.getHistory() ?? []
        
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
            return 
        }
        
        let selectedItem = history[sender.tag]
        
        // Copy to clipboard - user can paste manually with ⌘V
        clipboardManager?.copySelectedItem(selectedItem)
    }
    
    @objc func clearHistory() {
        clipboardManager?.clearHistory()
        updateMenu()
    }

    @objc func quit() {
        hotkeyManager?.unregisterHotkey()
        clipboardManager?.stopMonitoring()
        clipboardPopup?.hide()
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - ClipboardManagerDelegate
extension AppDelegate: ClipboardManagerDelegate {
    func clipboardDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateMenu()
        }
    }
}

// MARK: - HotkeyManagerDelegate
extension AppDelegate: HotkeyManagerDelegate {
    func hotkeyPressed() {
        DispatchQueue.main.async { [weak self] in
            guard let history = self?.clipboardManager?.getHistory() else { 
                return 
            }
            
            self?.clipboardPopup?.show(with: history)
        }
    }
    

}

// MARK: - ClipboardPopupDelegate  
extension AppDelegate: ClipboardPopupDelegate {
    func popupDidSelectItem(_ item: String) {
        // Simply copy to clipboard - user can paste manually with ⌘V
        clipboardManager?.copySelectedItem(item)
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