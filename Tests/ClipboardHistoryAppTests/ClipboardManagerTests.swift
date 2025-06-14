import XCTest
@testable import ClipboardHistoryCore

final class ClipboardManagerTests: XCTestCase {
    var clipboardManager: ClipboardManager!
    var mockDelegate: MockClipboardManagerDelegate!
    
    override func setUp() {
        super.setUp()
        clipboardManager = ClipboardManager()
        mockDelegate = MockClipboardManagerDelegate()
        clipboardManager.delegate = mockDelegate
        
        // Clear any existing history for clean tests
        clipboardManager.clearHistory()
    }
    
    override func tearDown() {
        clipboardManager.stopMonitoring()
        clipboardManager.clearHistory()
        clipboardManager = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testInitialHistoryIsEmpty() {
        XCTAssertTrue(clipboardManager.getHistory().isEmpty, "Initial history should be empty")
    }
    
    func testCopyToClipboard() {
        let testContent = "Test clipboard content"
        
        clipboardManager.copyToClipboard(testContent)
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 1, "History should contain one item")
        XCTAssertEqual(history.first, testContent, "History should contain the copied content")
        XCTAssertTrue(mockDelegate.clipboardDidChangeWasCalled, "Delegate should be notified")
    }
    
    func testCopyEmptyStringDoesNothing() {
        clipboardManager.copyToClipboard("")
        
        let history = clipboardManager.getHistory()
        XCTAssertTrue(history.isEmpty, "Empty string should not be added to history")
        XCTAssertFalse(mockDelegate.clipboardDidChangeWasCalled, "Delegate should not be called for empty string")
    }
    
    func testCopySelectedItem() {
        let testContent = "Test selected content"
        
        clipboardManager.copySelectedItem(testContent)
        
        let history = clipboardManager.getHistory()
        XCTAssertTrue(history.isEmpty, "copySelectedItem should not add to history")
        XCTAssertFalse(mockDelegate.clipboardDidChangeWasCalled, "Delegate should not be called for copySelectedItem")
    }
    
    // MARK: - History Management Tests
    
    func testMultipleItemsInHistory() {
        let items = ["First item", "Second item", "Third item"]
        
        for item in items {
            clipboardManager.copyToClipboard(item)
        }
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 3, "History should contain all items")
        XCTAssertEqual(history[0], "Third item", "Most recent item should be first")
        XCTAssertEqual(history[1], "Second item", "Second most recent item should be second")
        XCTAssertEqual(history[2], "First item", "Oldest item should be last")
    }
    
    func testDuplicateItemMovesToTop() {
        let items = ["First item", "Second item", "Third item"]
        
        // Add initial items
        for item in items {
            clipboardManager.copyToClipboard(item)
        }
        
        // Add duplicate of first item
        clipboardManager.copyToClipboard("First item")
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 3, "History should still contain 3 unique items")
        XCTAssertEqual(history[0], "First item", "Duplicate item should move to top")
        XCTAssertEqual(history[1], "Third item", "Other items should shift down")
        XCTAssertEqual(history[2], "Second item", "Other items should shift down")
    }
    
    func testHistoryMaxSize() {
        // Add more than max size (20) items
        for i in 1...25 {
            clipboardManager.copyToClipboard("Item \(i)")
        }
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 20, "History should be limited to max size")
        XCTAssertEqual(history[0], "Item 25", "Most recent item should be first")
        XCTAssertEqual(history[19], "Item 6", "Oldest kept item should be last")
    }
    
    func testClearHistory() {
        // Add some items
        clipboardManager.copyToClipboard("Item 1")
        clipboardManager.copyToClipboard("Item 2")
        
        XCTAssertFalse(clipboardManager.getHistory().isEmpty, "History should have items before clearing")
        
        clipboardManager.clearHistory()
        
        XCTAssertTrue(clipboardManager.getHistory().isEmpty, "History should be empty after clearing")
    }
    
    func testDeleteItemAtValidIndex() {
        let items = ["First item", "Second item", "Third item"]
        
        for item in items {
            clipboardManager.copyToClipboard(item)
        }
        
        // Reset delegate call flag
        mockDelegate.clipboardDidChangeWasCalled = false
        
        clipboardManager.deleteItem(at: 1) // Delete "Second item"
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 2, "History should have one less item")
        XCTAssertEqual(history[0], "Third item", "First item should remain")
        XCTAssertEqual(history[1], "First item", "Third item should remain")
        XCTAssertTrue(mockDelegate.clipboardDidChangeWasCalled, "Delegate should be notified of deletion")
    }
    
    func testDeleteItemAtInvalidIndex() {
        clipboardManager.copyToClipboard("Test item")
        
        // Reset delegate call flag
        mockDelegate.clipboardDidChangeWasCalled = false
        
        clipboardManager.deleteItem(at: 5) // Invalid index
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 1, "History should be unchanged for invalid index")
        XCTAssertFalse(mockDelegate.clipboardDidChangeWasCalled, "Delegate should not be called for invalid index")
    }
    
    func testDeleteItemAtNegativeIndex() {
        clipboardManager.copyToClipboard("Test item")
        
        // Reset delegate call flag
        mockDelegate.clipboardDidChangeWasCalled = false
        
        clipboardManager.deleteItem(at: -1) // Negative index
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 1, "History should be unchanged for negative index")
        XCTAssertFalse(mockDelegate.clipboardDidChangeWasCalled, "Delegate should not be called for negative index")
    }
    
    // MARK: - Monitoring Tests
    
    func testStartAndStopMonitoring() {
        // These methods should not crash
        XCTAssertNoThrow(clipboardManager.startMonitoring(), "startMonitoring should not throw")
        XCTAssertNoThrow(clipboardManager.stopMonitoring(), "stopMonitoring should not throw")
    }
    
    // MARK: - Persistence Tests
    
    func testSaveHistoryOnExit() {
        clipboardManager.copyToClipboard("Test item for persistence")
        
        // This should not crash
        XCTAssertNoThrow(clipboardManager.saveHistoryOnExit(), "saveHistoryOnExit should not throw")
    }
    
    // MARK: - Popup Item Count Configuration Tests
    
    func testDefaultPopupItemCount() {
        let defaultCount = clipboardManager.getPopupItemCount()
        XCTAssertEqual(defaultCount, 3, "Default popup item count should be 3")
    }
    
    func testSetValidPopupItemCount() {
        clipboardManager.setPopupItemCount(5)
        let count = clipboardManager.getPopupItemCount()
        XCTAssertEqual(count, 5, "Should set valid popup item count")
    }
    
    func testSetPopupItemCountMinimum() {
        clipboardManager.setPopupItemCount(1)
        let count = clipboardManager.getPopupItemCount()
        XCTAssertEqual(count, 1, "Should accept minimum value of 1")
    }
    
    func testSetPopupItemCountMaximum() {
        clipboardManager.setPopupItemCount(20)
        let count = clipboardManager.getPopupItemCount()
        XCTAssertEqual(count, 20, "Should accept maximum value of 20")
    }
    
    func testSetPopupItemCountBelowMinimum() {
        clipboardManager.setPopupItemCount(0)
        let count = clipboardManager.getPopupItemCount()
        XCTAssertEqual(count, 1, "Should clamp to minimum value of 1")
    }
    
    func testSetPopupItemCountNegative() {
        clipboardManager.setPopupItemCount(-5)
        let count = clipboardManager.getPopupItemCount()
        XCTAssertEqual(count, 1, "Should clamp negative values to minimum of 1")
    }
    
    func testSetPopupItemCountAboveMaximum() {
        clipboardManager.setPopupItemCount(25)
        let count = clipboardManager.getPopupItemCount()
        XCTAssertEqual(count, 20, "Should clamp to maximum value of 20")
    }
    
    func testPopupItemCountPersistence() {
        // Set a custom value
        clipboardManager.setPopupItemCount(7)
        
        // Create a new instance to test persistence
        let newManager = ClipboardManager()
        let persistedCount = newManager.getPopupItemCount()
        
        XCTAssertEqual(persistedCount, 7, "Popup item count should persist between instances")
    }
}

// MARK: - Mock Delegate

class MockClipboardManagerDelegate: ClipboardManagerDelegate {
    var clipboardDidChangeWasCalled = false
    
    func clipboardDidChange() {
        clipboardDidChangeWasCalled = true
    }
} 