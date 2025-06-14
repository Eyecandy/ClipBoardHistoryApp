import SwiftUI
import AppKit
import ClipboardHistoryCore

// Create and run the app
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var clipboardManager: ClipboardHistoryCore.ClipboardManager?
    var hotkeyManager: ClipboardHistoryCore.HotkeyManager?
    var clipboardPopup: ClipboardHistoryCore.ClipboardPopup?

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
            button.image = NSImage(
                systemSymbolName: "scissors",
                accessibilityDescription: "Clipboard History"
            )
        }
        updateMenu()
    }
    
    private func setupClipboardManager() {
        clipboardManager = ClipboardHistoryCore.ClipboardManager()
        clipboardManager?.delegate = self
        clipboardManager?.startMonitoring()
    }
    
    private func setupHotkeyManager() {
        hotkeyManager = ClipboardHistoryCore.HotkeyManager()
        hotkeyManager?.delegate = self
        hotkeyManager?.registerHotkey()
    }
    
    private func setupClipboardPopup() {
        clipboardPopup = ClipboardHistoryCore.ClipboardPopup()
        clipboardPopup?.delegate = self
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        addHotkeyInfoToMenu(menu)
        addHistoryItemsToMenu(menu)
        addUtilityOptionsToMenu(menu)
        
        statusItem?.menu = menu
    }
    
    private func addHotkeyInfoToMenu(_ menu: NSMenu) {
        // Add info about hotkey (only if hotkey manager is set up)
        guard hotkeyManager != nil else { return }
        
        let hotkeyInfo = NSMenuItem(
            title: "Press ⌘⇧C for quick access",
            action: nil,
            keyEquivalent: ""
        )
        hotkeyInfo.isEnabled = false
        menu.addItem(hotkeyInfo)
        
        let copyInfo = NSMenuItem(
            title: "Click items to copy, then paste with ⌘V",
            action: nil,
            keyEquivalent: ""
        )
        copyInfo.isEnabled = false
        menu.addItem(copyInfo)
        menu.addItem(NSMenuItem.separator())
    }
    
    private func addHistoryItemsToMenu(_ menu: NSMenu) {
        // Add clipboard history items
        let history = clipboardManager?.getHistory() ?? []
        
        if history.isEmpty {
            let emptyItem = NSMenuItem(
                title: "No clipboard history",
                action: nil,
                keyEquivalent: ""
            )
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (index, item) in history.enumerated() {
                addHistoryItemToMenu(menu, item: item, index: index)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
    }
    
    private func addHistoryItemToMenu(_ menu: NSMenu, item: String, index: Int) {
        // Clean up multi-line text for menu display
        let menuTitle = item.cleanedForDisplay().truncated(to: 50)
        let menuItem = NSMenuItem(
            title: menuTitle,
            action: #selector(selectClipboardItem(_:)),
            keyEquivalent: ""
        )
        menuItem.tag = index
        menuItem.target = self
        
        // Add submenu for each item with options
        let submenu = NSMenu()
        
        let copyAction = NSMenuItem(
            title: "Copy",
            action: #selector(selectClipboardItem(_:)),
            keyEquivalent: ""
        )
        copyAction.tag = index
        copyAction.target = self
        submenu.addItem(copyAction)
        
        let viewFullAction = NSMenuItem(
            title: "View Full Text",
            action: #selector(viewFullClipboardItem(_:)),
            keyEquivalent: ""
        )
        viewFullAction.tag = index
        viewFullAction.target = self
        submenu.addItem(viewFullAction)
        
        let deleteAction = NSMenuItem(
            title: "Delete",
            action: #selector(deleteClipboardItem(_:)),
            keyEquivalent: ""
        )
        deleteAction.tag = index
        deleteAction.target = self
        submenu.addItem(deleteAction)
        
        menuItem.submenu = submenu
        menu.addItem(menuItem)
    }
    
    private func addUtilityOptionsToMenu(_ menu: NSMenu) {
        let history = clipboardManager?.getHistory() ?? []
        
        // Add clear history option
        if !history.isEmpty {
            let clearItem = NSMenuItem(
                title: "Clear History",
                action: #selector(clearHistory),
                keyEquivalent: ""
            )
            clearItem.target = self
            menu.addItem(clearItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        // Add settings submenu
        let settingsItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        let settingsSubmenu = NSMenu()
        
        // Add popup item count setting
        let popupSettingsItem = NSMenuItem(title: "Popup Items", action: nil, keyEquivalent: "")
        let popupSubmenu = NSMenu()
        
        let currentCount = clipboardManager?.getPopupItemCount() ?? 3
        
        for count in 1...20 {
            let countItem = NSMenuItem(
                title: "\(count) item\(count == 1 ? "" : "s")",
                action: #selector(setPopupItemCount(_:)),
                keyEquivalent: ""
            )
            countItem.tag = count
            countItem.target = self
            countItem.state = (count == currentCount) ? .on : .off
            popupSubmenu.addItem(countItem)
        }
        
        popupSettingsItem.submenu = popupSubmenu
        settingsSubmenu.addItem(popupSettingsItem)
        
        settingsItem.submenu = settingsSubmenu
        menu.addItem(settingsItem)
        menu.addItem(NSMenuItem.separator())
        
        // Add quit option
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
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
    
    @objc func deleteClipboardItem(_ sender: NSMenuItem) {
        clipboardManager?.deleteItem(at: sender.tag)
    }
    
    @objc func setPopupItemCount(_ sender: NSMenuItem) {
        clipboardManager?.setPopupItemCount(sender.tag)
        updateMenu() // Refresh menu to show new selection
    }
    
    @objc func viewFullClipboardItem(_ sender: NSMenuItem) {
        guard let history = clipboardManager?.getHistory(),
              sender.tag >= 0,
              sender.tag < history.count else { 
            return 
        }
        
        let item = history[sender.tag]
        showFullTextDialog(for: item)
    }
    
    private func showFullTextDialog(for text: String) {
        let alert = NSAlert()
        alert.messageText = "Full Clipboard Content"
        alert.informativeText = text
        alert.addButton(withTitle: "Copy")
        alert.addButton(withTitle: "Close")
        alert.alertStyle = .informational
        
        // Make the alert resizable for long text
        alert.window.setContentSize(NSSize(width: 500, height: 400))
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            clipboardManager?.copySelectedItem(text)
        }
    }

    @objc func quit() {
        hotkeyManager?.unregisterHotkey()
        clipboardManager?.stopMonitoring()
        clipboardPopup?.hide()
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Ensure history is saved when app quits
        clipboardManager?.saveHistoryOnExit()
    }
}

// MARK: - ClipboardManagerDelegate
extension AppDelegate: ClipboardHistoryCore.ClipboardManagerDelegate {
    func clipboardDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateMenu()
        }
    }
}

// MARK: - HotkeyManagerDelegate
extension AppDelegate: ClipboardHistoryCore.HotkeyManagerDelegate {
    func hotkeyPressed() {
        DispatchQueue.main.async { [weak self] in
            guard let history = self?.clipboardManager?.getHistory() else { 
                return 
            }
            
            let maxItems = self?.clipboardManager?.getPopupItemCount() ?? 3
            self?.clipboardPopup?.show(with: history, maxItems: maxItems)
        }
    }
}

// MARK: - ClipboardPopupDelegate  
extension AppDelegate: ClipboardHistoryCore.ClipboardPopupDelegate {
    func popupDidSelectItem(_ item: String) {
        // Simply copy to clipboard - user can paste manually with ⌘V
        clipboardManager?.copySelectedItem(item)
    }
    
    func popupDidRequestFullView(_ item: String) {
        showFullTextDialog(for: item)
    }
    
    func popupDidRequestDelete(_ item: String) {
        guard let history = clipboardManager?.getHistory(),
              let index = history.firstIndex(of: item) else { 
            return 
        }
        clipboardManager?.deleteItem(at: index)
    }
} 
