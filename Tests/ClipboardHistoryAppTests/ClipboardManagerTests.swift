import XCTest
@testable import ClipboardHistoryCore

final class ClipboardManagerTests: XCTestCase {
    var clipboardManager: ClipboardManager!
    var mockDelegate: MockClipboardManagerDelegate!
    
    override func setUp() {
        super.setUp()
        
        // Clear any existing settings for clean tests
        UserDefaults.standard.removeObject(forKey: "ClipboardHistory")
        UserDefaults.standard.removeObject(forKey: "ClipboardPinned")
        UserDefaults.standard.removeObject(forKey: "PopupItemCount")
        UserDefaults.standard.removeObject(forKey: "PopupItemCount_set")
        UserDefaults.standard.removeObject(forKey: "PopupTimeout")
        UserDefaults.standard.removeObject(forKey: "PopupTimeout_set")
        UserDefaults.standard.synchronize()
        
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
    
    // MARK: - Direct Hotkey Support Tests
    
    func testDirectHotkeyItemAccess() {
        // Add test items
        let items = ["First item", "Second item", "Third item", "Fourth item", "Fifth item", "Sixth item", "Seventh item"]
        for item in items {
            clipboardManager.copyToClipboard(item)
        }
        
        let history = clipboardManager.getHistory()
        
        // Test that we can access items by index (simulating direct hotkey access)
        XCTAssertEqual(history[0], "Seventh item", "First item should be most recent")
        XCTAssertEqual(history[1], "Sixth item", "Second item should be second most recent")
        XCTAssertEqual(history[2], "Fifth item", "Third item should be third most recent")
        XCTAssertEqual(history[3], "Fourth item", "Fourth item should be fourth most recent")
        XCTAssertEqual(history[4], "Third item", "Fifth item should be fifth most recent")
        XCTAssertEqual(history[5], "Second item", "Sixth item should be sixth most recent")
        
        // Test boundary - accessing 7th item when only 6 direct hotkeys exist
        XCTAssertTrue(history.count >= 6, "Should have at least 6 items for direct hotkey access")
    }
    
    func testDirectHotkeyWithLimitedHistory() {
        // Test with fewer than 6 items
        clipboardManager.copyToClipboard("Only item")
        clipboardManager.copyToClipboard("Second item")
        clipboardManager.copyToClipboard("Third item")
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 3, "Should have exactly 3 items")
        
        // Direct hotkeys 1-3 should work, 4-6 should be gracefully handled
        XCTAssertEqual(history[0], "Third item", "⌘⌥1 should access first item")
        XCTAssertEqual(history[1], "Second item", "⌘⌥2 should access second item")
        XCTAssertEqual(history[2], "Only item", "⌘⌥3 should access third item")
        
        // Indices 3-5 would be out of bounds - this tests the safety of direct hotkey implementation
        XCTAssertTrue(history.count < 6, "Should have fewer than 6 items to test boundary conditions")
    }
    
    func testDirectHotkeyBoundaryConditions() {
        // Test empty history
        let emptyHistory = clipboardManager.getHistory()
        XCTAssertTrue(emptyHistory.isEmpty, "History should be empty initially")
        
        // Add exactly 6 items
        for i in 1...6 {
            clipboardManager.copyToClipboard("Item \(i)")
        }
        
        let history = clipboardManager.getHistory()
        XCTAssertEqual(history.count, 6, "Should have exactly 6 items")
        
        // All 6 direct hotkeys should have valid targets
        for i in 0..<6 {
            XCTAssertTrue(i < history.count, "Index \(i) should be valid for direct hotkey ⌘⌥\(i + 1)")
        }
    }
    
    // MARK: - Pinned Items Tests
    
    func testInitialPinnedItemsEmpty() {
        XCTAssertTrue(clipboardManager.getPinnedItems().isEmpty, "Initial pinned items should be empty")
    }
    
    func testPinItem() {
        let testItem = "Test pinned item"
        
        clipboardManager.pinItem(testItem)
        
        let pinnedItems = clipboardManager.getPinnedItems()
        XCTAssertEqual(pinnedItems.count, 1, "Should have one pinned item")
        XCTAssertEqual(pinnedItems.first, testItem, "Pinned item should match")
        XCTAssertTrue(clipboardManager.isPinned(testItem), "Item should be marked as pinned")
        XCTAssertTrue(mockDelegate.clipboardDidChangeWasCalled, "Delegate should be notified")
    }
    
    func testPinMultipleItems() {
        let items = ["First pinned", "Second pinned", "Third pinned"]
        
        for item in items {
            clipboardManager.pinItem(item)
        }
        
        let pinnedItems = clipboardManager.getPinnedItems()
        XCTAssertEqual(pinnedItems.count, 3, "Should have all pinned items")
        XCTAssertEqual(pinnedItems[0], "Third pinned", "Most recently pinned should be first")
        XCTAssertEqual(pinnedItems[1], "Second pinned", "Second most recent should be second")
        XCTAssertEqual(pinnedItems[2], "First pinned", "Oldest pinned should be last")
    }
    
    func testPinDuplicateMovesToTop() {
        let items = ["First pinned", "Second pinned", "Third pinned"]
        
        for item in items {
            clipboardManager.pinItem(item)
        }
        
        // Pin first item again
        clipboardManager.pinItem("First pinned")
        
        let pinnedItems = clipboardManager.getPinnedItems()
        XCTAssertEqual(pinnedItems.count, 3, "Should still have 3 unique pinned items")
        XCTAssertEqual(pinnedItems[0], "First pinned", "Re-pinned item should move to top")
    }
    
    func testUnpinItem() {
        let testItem = "Test pinned item"
        
        clipboardManager.pinItem(testItem)
        XCTAssertTrue(clipboardManager.isPinned(testItem), "Item should be pinned")
        
        clipboardManager.unpinItem(testItem)
        
        XCTAssertFalse(clipboardManager.isPinned(testItem), "Item should no longer be pinned")
        XCTAssertTrue(clipboardManager.getPinnedItems().isEmpty, "Pinned items should be empty")
    }
    
    func testPinnedItemsMaxSize() {
        // Pin more than max size (10) items
        for i in 1...15 {
            clipboardManager.pinItem("Pinned item \(i)")
        }
        
        let pinnedItems = clipboardManager.getPinnedItems()
        XCTAssertEqual(pinnedItems.count, 10, "Pinned items should be limited to max size")
        XCTAssertEqual(pinnedItems[0], "Pinned item 15", "Most recent should be first")
        XCTAssertEqual(pinnedItems[9], "Pinned item 6", "Oldest kept should be last")
    }
    
    func testClearPinnedItems() {
        clipboardManager.pinItem("Item 1")
        clipboardManager.pinItem("Item 2")
        
        XCTAssertFalse(clipboardManager.getPinnedItems().isEmpty, "Should have pinned items")
        
        clipboardManager.clearPinnedItems()
        
        XCTAssertTrue(clipboardManager.getPinnedItems().isEmpty, "Pinned items should be empty")
    }
    
    func testDeletePinnedItem() {
        let items = ["First", "Second", "Third"]
        for item in items {
            clipboardManager.pinItem(item)
        }
        
        clipboardManager.deletePinnedItem(at: 1) // Delete "Second"
        
        let pinnedItems = clipboardManager.getPinnedItems()
        XCTAssertEqual(pinnedItems.count, 2, "Should have one less pinned item")
        XCTAssertEqual(pinnedItems[0], "Third", "First item should remain")
        XCTAssertEqual(pinnedItems[1], "First", "Last item should remain")
    }
    
    func testGetCurrentClipboardItem() {
        // This tests the getCurrentClipboardItem method
        let _ = clipboardManager.getCurrentClipboardItem()
        // Since we can't control the actual system clipboard in tests,
        // we just ensure the method doesn't crash
        XCTAssertNoThrow(clipboardManager.getCurrentClipboardItem(), "getCurrentClipboardItem should not crash")
    }
    
    // MARK: - Popup Timeout Tests
    
    func testDefaultPopupTimeout() {
        let defaultTimeout = clipboardManager.getPopupTimeout()
        XCTAssertEqual(defaultTimeout, 10, "Default popup timeout should be 10 seconds")
    }
    
    func testSetValidPopupTimeout() {
        clipboardManager.setPopupTimeout(30)
        let timeout = clipboardManager.getPopupTimeout()
        XCTAssertEqual(timeout, 30, "Should set valid popup timeout")
    }
    
    func testSetPopupTimeoutMinimum() {
        clipboardManager.setPopupTimeout(0)
        let timeout = clipboardManager.getPopupTimeout()
        XCTAssertEqual(timeout, 0, "Should accept minimum value of 0 (never hide)")
    }
    
    func testSetPopupTimeoutMaximum() {
        clipboardManager.setPopupTimeout(300)
        let timeout = clipboardManager.getPopupTimeout()
        XCTAssertEqual(timeout, 300, "Should accept maximum value of 300 (5 minutes)")
    }
    
    func testSetPopupTimeoutAboveMaximum() {
        clipboardManager.setPopupTimeout(400)
        let timeout = clipboardManager.getPopupTimeout()
        XCTAssertEqual(timeout, 300, "Should clamp to maximum value of 300")
    }
    
    func testSetPopupTimeoutNegative() {
        clipboardManager.setPopupTimeout(-10)
        let timeout = clipboardManager.getPopupTimeout()
        XCTAssertEqual(timeout, 0, "Should clamp negative values to 0")
    }
    
    func testPopupTimeoutDisplayString() {
        // Test various timeout values and their display strings
        clipboardManager.setPopupTimeout(0)
        XCTAssertEqual(clipboardManager.getPopupTimeoutDisplayString(), "Never (manual dismiss only)")
        
        clipboardManager.setPopupTimeout(5)
        XCTAssertEqual(clipboardManager.getPopupTimeoutDisplayString(), "5 seconds")
        
        clipboardManager.setPopupTimeout(1)
        XCTAssertEqual(clipboardManager.getPopupTimeoutDisplayString(), "1 second")
        
        clipboardManager.setPopupTimeout(60)
        XCTAssertEqual(clipboardManager.getPopupTimeoutDisplayString(), "1 minute")
        
        clipboardManager.setPopupTimeout(120)
        XCTAssertEqual(clipboardManager.getPopupTimeoutDisplayString(), "2 minutes")
        
        clipboardManager.setPopupTimeout(90)
        XCTAssertEqual(clipboardManager.getPopupTimeoutDisplayString(), "1m 30s")
        
        clipboardManager.setPopupTimeout(185)
        XCTAssertEqual(clipboardManager.getPopupTimeoutDisplayString(), "3m 5s")
    }
    
    func testPopupTimeoutPersistence() {
        clipboardManager.setPopupTimeout(45)
        
        // Create new instance to test persistence
        let newManager = ClipboardManager()
        let persistedTimeout = newManager.getPopupTimeout()
        
        XCTAssertEqual(persistedTimeout, 45, "Popup timeout should persist between instances")
    }
}

// MARK: - Mock Delegate

class MockClipboardManagerDelegate: ClipboardManagerDelegate {
    var clipboardDidChangeWasCalled = false
    
    func clipboardDidChange() {
        clipboardDidChangeWasCalled = true
    }
} 