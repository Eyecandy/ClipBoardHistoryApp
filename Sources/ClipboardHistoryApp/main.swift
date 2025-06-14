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
    var hasShownPermissionAlert = false

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
    
    private func checkAccessibilityPermissions() {
        let trusted = AXIsProcessTrusted()
        print("🔐 Accessibility permissions: \(trusted ? "✅ GRANTED" : "❌ NOT GRANTED")")
        
        // Debug: Print current executable info
        let executablePath = Bundle.main.executablePath ?? "Unknown"
        let bundlePath = Bundle.main.bundlePath
        print("📍 Current executable: \(executablePath)")
        print("📦 Bundle path: \(bundlePath)")
        print("🆔 Bundle identifier: \(Bundle.main.bundleIdentifier ?? "None")")
        
        if !trusted {
            print("⚠️  To enable paste functionality, please:")
            print("1. Open System Settings > Privacy & Security > Accessibility")
            print("2. Add this app to the list: \(bundlePath)")
            print("3. Make sure to toggle it ON")
            print("4. Restart the app")
            
            // Show immediate alert about permissions (only once)
            if !hasShownPermissionAlert {
                hasShownPermissionAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.showAccessibilityPermissionAlert()
                }
            }
        }
    }
    
    private func showAccessibilityPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        ClipboardHistoryApp needs accessibility permission to paste text automatically.
        
        Without this permission:
        • The hotkey (⌘⇧V) will show clipboard items
        • You'll hear a system beep when trying to paste
        • You'll need to paste manually (⌘V)
        
        Grant permission now?
        """
        alert.addButton(withTitle: "Open Settings & Grant Permission")
        alert.addButton(withTitle: "Continue Without Auto-Paste")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            self.requestAccessibilityPermissions()
        }
    }
    
    private func requestAccessibilityPermissions() {
        // This will show the system permission dialog
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("🔐 After system prompt: \(trusted ? "✅ GRANTED" : "❌ STILL NOT GRANTED")")
        
        // Also open system settings as backup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.openAccessibilitySettings()
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
        
        // Just copy to clipboard - user can paste manually with ⌘V
        // No permission prompt needed for menu selections
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
    
    private func showPastePermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Enable Auto-Paste?"
        alert.informativeText = """
        ClipboardHistoryApp can automatically paste the selected text for you.
        
        This requires accessibility permission to simulate keyboard shortcuts.
        
        Without permission:
        • Text is copied to clipboard
        • You manually paste with ⌘V
        
        With permission:
        • Text is automatically pasted where you're typing
        """
        alert.addButton(withTitle: "Grant Permission & Auto-Paste")
        alert.addButton(withTitle: "Just Copy (Manual Paste)")
        alert.alertStyle = .informational
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            self.requestAccessibilityPermissions()
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
            // Show permission request dialog only when user tries to paste
            if !hasShownPermissionAlert {
                hasShownPermissionAlert = true
                DispatchQueue.main.async {
                    self.showPastePermissionAlert()
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
        print("🔄 Simulating paste...")
        
        // Get the frontmost application info (before showing popup)
        let workspace = NSWorkspace.shared
        guard let frontApp = workspace.frontmostApplication else {
            print("❌ No frontmost application found")
            showPasteError("No target application found. Please click in a text field first.")
            return
        }
        
        print("🎯 Target app: \(frontApp.localizedName ?? "Unknown") (PID: \(frontApp.processIdentifier))")
        
        // Check if target app is our own app (which means paste will fail)
        if frontApp.bundleIdentifier == Bundle.main.bundleIdentifier {
            showPasteError("No target application selected. Please click in a text field in another app first.")
            return
        }
        
        // Give time for popup to hide and activate the target app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Activate the target application to ensure it receives the paste
            let activationResult = frontApp.activate(options: [])
            print("🔄 App activation result: \(activationResult)")
            
            // Small additional delay to ensure activation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Double-check that the app is still the frontmost
                if let currentFrontApp = workspace.frontmostApplication {
                    print("🔍 Current frontmost app after activation: \(currentFrontApp.localizedName ?? "Unknown")")
                    
                    if currentFrontApp.bundleIdentifier != frontApp.bundleIdentifier {
                        self.showPasteError("Failed to activate target application '\(frontApp.localizedName ?? "Unknown")'. Try clicking in the app first.")
                        return
                    }
                }
                
                self.simulatePaste()
            }
        }
    }
    
    private func simulatePaste() {
        print("📋 Attempting to simulate Cmd+V paste...")
        
        // Try using the combined session state which is more reliable
        guard let source = CGEventSource(stateID: .combinedSessionState) else { 
            print("❌ Failed to create event source")
            showPasteError("Failed to create event source. This might be a system permission issue.")
            return 
        }
        
        // Create key down and key up events for 'V' key (virtual key code 9)
        guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { 
            print("❌ Failed to create key events")
            showPasteError("Failed to create keyboard events. macOS might be blocking event creation.")
            return 
        }
        
        // Set Command modifier flag
        keyDownEvent.flags = .maskCommand
        keyUpEvent.flags = .maskCommand
        
        // Post the events using the session event tap
        print("📤 Posting Cmd+V key down...")
        keyDownEvent.post(tap: .cgSessionEventTap)
        print("✅ Key down event posted")
        
        // Small delay between key down and key up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            print("📤 Posting Cmd+V key up...")
            keyUpEvent.post(tap: .cgSessionEventTap)
            print("✅ Key up event posted")
            
            // Check if paste actually worked by monitoring clipboard activity
            self.verifyPasteSuccess()
        }
    }
    
    private func verifyPasteSuccess() {
        var hasShownError = false
        
        // Wait a moment for the paste to potentially occur
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // We can't directly verify if paste worked, but we can check common failure scenarios
            let workspace = NSWorkspace.shared
            if let frontApp = workspace.frontmostApplication {
                print("🔍 Final frontmost app: \(frontApp.localizedName ?? "Unknown")")
                
                // If our app is still frontmost, paste likely failed
                if frontApp.bundleIdentifier == Bundle.main.bundleIdentifier && !hasShownError {
                    hasShownError = true
                    self.showPasteError("Paste may have failed - no target application detected. Try clicking in a text field first.")
                }
            }
        }
        
        // Also set up a system event monitor to detect if there's a system beep/error
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.systemDefined]) { event in
            print("🔍 System event detected: \(event)")
        }
        
        // Remove the monitor after a short time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
    
    private func showPasteError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Paste Failed"
            alert.informativeText = """
            \(message)
            
            Troubleshooting tips:
            • Make sure you clicked in a text field before using the hotkey
            • Try clicking in the target app first, then use ⌘⇧V
            • Some apps don't accept simulated keyboard input
            • You can always paste manually with ⌘V after selecting an item
            """
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Open Accessibility Settings")
            alert.alertStyle = .warning
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                self.openAccessibilitySettings()
            }
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