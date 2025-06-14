import XCTest
import HotKey
@testable import ClipboardHistoryApp

final class ClipboardIntegrationTests: XCTestCase {
    var clipboardManager: ClipboardManager!
    var shortcutManager: KeyboardShortcutManager!
    
    override func setUp() {
        super.setUp()
        clipboardManager = ClipboardManager.shared
        shortcutManager = KeyboardShortcutManager.shared
        clipboardManager.clearHistory()
    }
    
    override func tearDown() {
        clipboardManager.clearHistory()
        super.tearDown()
    }
    
    func testShortcutTriggersPasteMenu() {
        // Add some items to clipboard history
        let item1 = ClipboardItem(content: "Test 1", timestamp: Date())
        let item2 = ClipboardItem(content: "Test 2", timestamp: Date())
        clipboardManager.copyToClipboard(item1)
        clipboardManager.copyToClipboard(item2)
        
        // Simulate shortcut press
        shortcutManager.pasteHotKey?.keyDownHandler?()
        
        // Verify clipboard content was updated
        // Note: This is a simplified test as we can't easily test the menu UI
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), "Test 1")
    }
    
    func testShortcutWithEmptyHistory() {
        // Ensure history is empty
        clipboardManager.clearHistory()
        
        // Simulate shortcut press
        shortcutManager.pasteHotKey?.keyDownHandler?()
        
        // Verify clipboard content remains unchanged
        XCTAssertNil(NSPasteboard.general.string(forType: .string))
    }
    
    func testShortcutAfterHistoryClear() {
        // Add items and then clear
        let item = ClipboardItem(content: "Test", timestamp: Date())
        clipboardManager.copyToClipboard(item)
        clipboardManager.clearHistory()
        
        // Simulate shortcut press
        shortcutManager.pasteHotKey?.keyDownHandler?()
        
        // Verify no items are available
        XCTAssertTrue(clipboardManager.clipboardItems.isEmpty)
    }
    
    func testShortcutWithMaxItems() {
        // Fill history to max
        for i in 0..<60 {
            let item = ClipboardItem(content: "Test \(i)", timestamp: Date())
            clipboardManager.copyToClipboard(item)
        }
        
        // Simulate shortcut press
        shortcutManager.pasteHotKey?.keyDownHandler?()
        
        // Verify we still have max items
        XCTAssertEqual(clipboardManager.clipboardItems.count, 50)
    }
} 