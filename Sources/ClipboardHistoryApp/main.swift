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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
        
        setupStatusItem()
        clipboardManager = ClipboardManager()
        clipboardManager?.delegate = self
        clipboardManager?.startMonitoring()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "Clipboard History")
        }
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
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
              sender.tag < history.count else { return }
        
        let selectedItem = history[sender.tag]
        clipboardManager?.copyToClipboard(selectedItem)
    }
    
    @objc func clearHistory() {
        clipboardManager?.clearHistory()
        updateMenu()
    }

    @objc func quit() {
        clipboardManager?.stopMonitoring()
        NSApplication.shared.terminate(nil)
    }
}

extension AppDelegate: ClipboardManagerDelegate {
    func clipboardDidChange() {
        updateMenu()
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