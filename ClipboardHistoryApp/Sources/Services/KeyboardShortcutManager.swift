import Foundation
import AppKit
import HotKey

class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()
    @Published var pasteHotKey: HotKey?
    @Published var currentKey: Key
    @Published var currentModifiers: NSEvent.ModifierFlags
    
    // Default shortcut
    private let defaultShortcut = (key: Key.v, modifiers: NSEvent.ModifierFlags.command)
    
    // UserDefaults keys
    private let shortcutKeyKey = "pasteShortcutKey"
    private let shortcutModifiersKey = "pasteShortcutModifiers"
    
    private init() {
        self.currentKey = defaultShortcut.key
        self.currentModifiers = defaultShortcut.modifiers
        loadShortcut()
    }
    
    func loadShortcut() {
        // Load saved shortcut or use default
        let keyCode = UserDefaults.standard.integer(forKey: shortcutKeyKey)
        let modifiersRaw = UserDefaults.standard.integer(forKey: shortcutModifiersKey)
        
        let key = keyCode > 0 ? Key(carbonKeyCode: UInt32(keyCode)) ?? defaultShortcut.key : defaultShortcut.key
        let modifiers = modifiersRaw > 0 ? NSEvent.ModifierFlags(rawValue: UInt(modifiersRaw)) : defaultShortcut.modifiers
        
        setupPasteShortcut(key: key, modifiers: modifiers)
    }
    
    func saveShortcut(key: Key, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(key.carbonKeyCode, forKey: shortcutKeyKey)
        UserDefaults.standard.set(modifiers.rawValue, forKey: shortcutModifiersKey)
        setupPasteShortcut(key: key, modifiers: modifiers)
    }
    
    private func setupPasteShortcut(key: Key, modifiers: NSEvent.ModifierFlags) {
        // Remove existing hotkey if any
        pasteHotKey = nil
        currentKey = key
        currentModifiers = modifiers
        
        // Create new hotkey
        pasteHotKey = HotKey(key: key, modifiers: modifiers)
        pasteHotKey?.keyDownHandler = {
            self.showPasteMenu()
        }
    }
    
    private func showPasteMenu() {
        // Get the current mouse location
        let mouseLocation = NSEvent.mouseLocation
        
        // Create and show the paste menu
        let menu = NSMenu()
        
        // Add clipboard items
        for item in ClipboardManager.shared.clipboardItems {
            let menuItem = NSMenuItem(
                title: item.content,
                action: #selector(handlePaste(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = item
            menu.addItem(menuItem)
        }
        
        // Show menu at mouse location
        menu.popUp(positioning: nil, at: mouseLocation, in: nil)
    }
    
    @objc private func handlePaste(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipboardItem else { return }
        ClipboardManager.shared.copyToClipboard(item)
        
        // Simulate CMD+V
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
} 