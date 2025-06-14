import XCTest
@testable import ClipboardHistoryCore

final class ClipboardPopupTests: XCTestCase {
    var clipboardPopup: ClipboardPopup!
    var mockDelegate: MockClipboardPopupDelegate!
    
    override func setUp() {
        super.setUp()
        clipboardPopup = ClipboardPopup()
        mockDelegate = MockClipboardPopupDelegate()
        clipboardPopup.delegate = mockDelegate
    }
    
    override func tearDown() {
        clipboardPopup.hide()
        clipboardPopup = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testInitialization() {
        XCTAssertNotNil(clipboardPopup, "ClipboardPopup should initialize successfully")
        XCTAssertNotNil(clipboardPopup.delegate, "Delegate should be set")
    }
    
    func testShowWithEmptyItems() {
        // This should not crash and should not show anything
        XCTAssertNoThrow(clipboardPopup.show(with: []), "show with empty items should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: [], maxItems: 5), "show with empty items and maxItems should not throw")
    }
    
    func testHideWithoutShow() {
        // Should not crash when hiding without showing first
        XCTAssertNoThrow(clipboardPopup.hide(), "hide without show should not throw")
    }
    
    // MARK: - Max Items Configuration Tests
    
    func testShowWithDefaultMaxItems() {
        let items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
        
        // Default should show 3 items
        XCTAssertNoThrow(clipboardPopup.show(with: items), "show with default maxItems should not throw")
    }
    
    func testShowWithCustomMaxItems() {
        let items = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
        
        // Should handle various maxItems values
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 1), "show with maxItems 1 should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 5), "show with maxItems 5 should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 20), "show with maxItems 20 should not throw")
    }
    
    func testShowWithMaxItemsBelowMinimum() {
        let items = ["Item 1", "Item 2", "Item 3"]
        
        // Should handle invalid maxItems values gracefully
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 0), "show with maxItems 0 should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: -5), "show with negative maxItems should not throw")
    }
    
    func testShowWithMaxItemsAboveMaximum() {
        let items = ["Item 1", "Item 2", "Item 3"]
        
        // Should handle maxItems above maximum gracefully
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 25), "show with maxItems 25 should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 100), "show with maxItems 100 should not throw")
    }
    
    func testShowWithMoreItemsThanMax() {
        let items = Array(1...10).map { "Item \($0)" }
        
        // Should handle cases where we have more items than maxItems
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 3), "show with more items than max should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 1), "show with many items, max 1 should not throw")
    }
    
    func testShowWithFewerItemsThanMax() {
        let items = ["Item 1", "Item 2"]
        
        // Should handle cases where we have fewer items than maxItems
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 5), "show with fewer items than max should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 20), "show with few items, max 20 should not throw")
    }
    
    // MARK: - Edge Cases
    
    func testMultipleShowCalls() {
        let items1 = ["Item 1", "Item 2"]
        let items2 = ["Item A", "Item B", "Item C"]
        
        // Multiple show calls should not crash
        XCTAssertNoThrow(clipboardPopup.show(with: items1, maxItems: 2), "first show should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: items2, maxItems: 3), "second show should not throw")
    }
    
    func testShowHideShow() {
        let items = ["Item 1", "Item 2", "Item 3"]
        
        // Show, hide, show sequence should work
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 2), "show should not throw")
        XCTAssertNoThrow(clipboardPopup.hide(), "hide should not throw")
        XCTAssertNoThrow(clipboardPopup.show(with: items, maxItems: 3), "show after hide should not throw")
    }
    
    // MARK: - Delegate Tests
    
    func testDelegateAssignment() {
        let newDelegate = MockClipboardPopupDelegate()
        clipboardPopup.delegate = newDelegate
        
        XCTAssertTrue(clipboardPopup.delegate === newDelegate, "Delegate should be properly assigned")
    }
    
    func testWeakDelegateReference() {
        var delegate: MockClipboardPopupDelegate? = MockClipboardPopupDelegate()
        clipboardPopup.delegate = delegate
        
        XCTAssertNotNil(clipboardPopup.delegate, "Delegate should be set")
        
        delegate = nil
        
        // The delegate should be nil due to weak reference
        XCTAssertNil(clipboardPopup.delegate, "Delegate should be nil after being deallocated")
    }
}

// MARK: - Mock Delegate

class MockClipboardPopupDelegate: ClipboardPopupDelegate {
    var popupDidSelectItemWasCalled = false
    var popupDidRequestFullViewWasCalled = false
    var popupDidRequestDeleteWasCalled = false
    var lastSelectedItem: String?
    var lastViewedItem: String?
    var lastDeletedItem: String?
    
    func popupDidSelectItem(_ item: String) {
        popupDidSelectItemWasCalled = true
        lastSelectedItem = item
    }
    
    func popupDidRequestFullView(_ item: String) {
        popupDidRequestFullViewWasCalled = true
        lastViewedItem = item
    }
    
    func popupDidRequestDelete(_ item: String) {
        popupDidRequestDeleteWasCalled = true
        lastDeletedItem = item
    }
} 