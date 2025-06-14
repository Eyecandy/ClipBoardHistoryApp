import XCTest
import HotKey
@testable import ClipboardHistoryApp

final class KeyboardShortcutManagerTests: XCTestCase {
    var shortcutManager: KeyboardShortcutManager!
    
    override func setUp() {
        super.setUp()
        shortcutManager = KeyboardShortcutManager.shared
        // Reset to default shortcut
        shortcutManager.saveShortcut(key: .v, modifiers: [.command])
    }
    
    func testDefaultShortcut() {
        XCTAssertNotNil(shortcutManager.pasteHotKey)
        XCTAssertEqual(shortcutManager.pasteHotKey?.key, .v)
        XCTAssertEqual(shortcutManager.pasteHotKey?.modifiers, [.command])
    }
    
    func testSaveShortcut() {
        // Save a new shortcut
        shortcutManager.saveShortcut(key: .c, modifiers: [.command, .shift])
        
        // Verify the shortcut was saved
        XCTAssertEqual(shortcutManager.pasteHotKey?.key, .c)
        XCTAssertEqual(shortcutManager.pasteHotKey?.modifiers, [.command, .shift])
    }
    
    func testLoadShortcut() {
        // Save a custom shortcut
        shortcutManager.saveShortcut(key: .x, modifiers: [.command, .option])
        
        // Create a new instance to test loading
        let newManager = KeyboardShortcutManager.shared
        
        // Verify the shortcut was loaded
        XCTAssertEqual(newManager.pasteHotKey?.key, .x)
        XCTAssertEqual(newManager.pasteHotKey?.modifiers, [.command, .option])
    }
    
    func testShortcutPersistence() {
        // Save a custom shortcut
        shortcutManager.saveShortcut(key: .z, modifiers: [.command, .control])
        
        // Verify UserDefaults was updated
        let savedKey = UserDefaults.standard.integer(forKey: "pasteShortcutKey")
        let savedModifiers = UserDefaults.standard.integer(forKey: "pasteShortcutModifiers")
        
        XCTAssertEqual(savedKey, Key.z.rawValue)
        XCTAssertEqual(savedModifiers, Int([.command, .control].rawValue))
    }
} 