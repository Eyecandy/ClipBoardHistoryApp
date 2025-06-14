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
        
        // Check accessibility permissions
        checkAccessibilityPermissions()
        
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
    
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        print("🔐 Accessibility permissions: \(trusted ? "✅ GRANTED" : "❌ NOT GRANTED")")
        
        if !trusted {
            print("⚠️  To enable paste functionality, please:")
            print("1. Open System Settings > Privacy & Security > Accessibility")
            print("2. Add this app to the list")
            print("3. Restart the app")
            
            // Request permissions
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
            print("🔐 After prompt: \(trusted ? "✅ GRANTED" : "❌ STILL NOT GRANTED")")
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
        
        // Add accessibility status
        let trusted = AXIsProcessTrusted()
        let accessibilityStatus = NSMenuItem(title: trusted ? "✅ Paste enabled" : "⚠️  Accessibility needed for paste", action: trusted ? nil : #selector(openAccessibilitySettings), keyEquivalent: "")
        accessibilityStatus.isEnabled = !trusted
        accessibilityStatus.target = self
        menu.addItem(accessibilityStatus)
        
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
    
    @objc func openAccessibilitySettings() {
        print("Opening accessibility settings...")
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
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
        
        // Check accessibility permissions before trying to paste
        let trusted = AXIsProcessTrusted()
        print("🔐 Accessibility trusted for paste: \(trusted)")
        
        if !trusted {
            print("❌ Cannot paste: Accessibility permissions required")
            // Show alert or notification
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "To enable automatic pasting, please grant accessibility permission in System Settings > Privacy & Security > Accessibility"
                alert.addButton(withTitle: "Open Settings")
                alert.addButton(withTitle: "Cancel")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    self.openAccessibilitySettings()
                }
            }
            return
        }
        
        // Try multiple paste methods
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.simulatePasteWithMultipleMethods()
        }
    }
    
    private func simulatePasteWithMultipleMethods() {
        print("🔄 Trying multiple paste methods...")
        
        // Method 1: Standard CGEvent approach
        simulatePasteMethod1()
        
        // Method 2: Alternative event source
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePasteMethod2()
        }
        
        // Method 3: Using NSApplication
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.simulatePasteMethod3()
        }
    }
    
    private func simulatePasteMethod1() {
        print("📋 Method 1: Standard CGEvent with session tap")
        
        guard let source = CGEventSource(stateID: .combinedSessionState) else { 
            print("❌ Method 1: Failed to create event source")
            return 
        }
        
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { 
            print("❌ Method 1: Failed to create key events")
            return 
        }
        
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand
        
        print("📤 Method 1: Posting events...")
        keyDownEvent.post(tap: .cgSessionEventTap)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            keyUpEvent.post(tap: .cgSessionEventTap)
            print("✅ Method 1: Events posted")
        }
    }
    
    private func simulatePasteMethod2() {
        print("📋 Method 2: CGEvent with annotation session")
        
        guard let source = CGEventSource(stateID: .hidSystemState) else { 
            print("❌ Method 2: Failed to create HID event source")
            return 
        }
        
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { 
            print("❌ Method 2: Failed to create key events")
            return 
        }
        
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand
        
        print("📤 Method 2: Posting to annotation session...")
        keyDownEvent.post(tap: .cghidEventTap)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            keyUpEvent.post(tap: .cghidEventTap)
            print("✅ Method 2: Events posted")
        }
    }
    
    private func simulatePasteMethod3() {
        print("📋 Method 3: Using NSApplication sendEvent")
        
        // Get the current frontmost application
        let workspace = NSWorkspace.shared
        if let frontApp = workspace.frontmostApplication {
            print("🎯 Method 3: Target app: \(frontApp.localizedName ?? "Unknown")")
        }
        
        // Create NSEvent
        if let event = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: .command,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "v",
            charactersIgnoringModifiers: "v",
            isARepeat: false,
            keyCode: 9
        ) {
            print("📤 Method 3: Sending NSEvent...")
            NSApplication.shared.postEvent(event, atStart: false)
            print("✅ Method 3: NSEvent posted")
        } else {
            print("❌ Method 3: Failed to create NSEvent")
        }
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