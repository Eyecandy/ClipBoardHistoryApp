import XCTest
@testable import ClipboardHistoryApp

final class ClipboardManagerTests: XCTestCase {
    var clipboardManager: ClipboardManager!
    
    override func setUp() {
        super.setUp()
        clipboardManager = ClipboardManager.shared
        clipboardManager.clearHistory()
    }
    
    override func tearDown() {
        clipboardManager.clearHistory()
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertTrue(clipboardManager.clipboardItems.isEmpty)
    }
    
    func testCopyToClipboard() {
        let testString = "Test content"
        let item = ClipboardItem(content: testString, timestamp: Date())
        
        clipboardManager.copyToClipboard(item)
        
        // Verify clipboard content
        XCTAssertEqual(NSPasteboard.general.string(forType: .string), testString)
    }
    
    func testClearHistory() {
        // Add some items
        let item1 = ClipboardItem(content: "Test 1", timestamp: Date())
        let item2 = ClipboardItem(content: "Test 2", timestamp: Date())
        clipboardManager.copyToClipboard(item1)
        clipboardManager.copyToClipboard(item2)
        
        // Clear history
        clipboardManager.clearHistory()
        
        // Verify history is empty
        XCTAssertTrue(clipboardManager.clipboardItems.isEmpty)
    }
    
    func testMaxItemsLimit() {
        // Add more items than the max limit
        for i in 0..<60 {
            let item = ClipboardItem(content: "Test \(i)", timestamp: Date())
            clipboardManager.copyToClipboard(item)
        }
        
        // Verify we don't exceed max items
        XCTAssertLessThanOrEqual(clipboardManager.clipboardItems.count, 50)
    }
    
    func testDuplicatePrevention() {
        let testString = "Test content"
        let item = ClipboardItem(content: testString, timestamp: Date())
        
        // Add the same content twice
        clipboardManager.copyToClipboard(item)
        clipboardManager.copyToClipboard(item)
        
        // Verify only one instance exists
        XCTAssertEqual(clipboardManager.clipboardItems.count, 1)
    }
} 