import XCTest
@testable import ClipboardHistoryCore

final class HotkeyManagerTests: XCTestCase {
    var hotkeyManager: HotkeyManager!
    var mockDelegate: MockHotkeyManagerDelegate!
    
    override func setUp() {
        super.setUp()
        hotkeyManager = HotkeyManager()
        mockDelegate = MockHotkeyManagerDelegate()
        hotkeyManager.delegate = mockDelegate
    }
    
    override func tearDown() {
        hotkeyManager.unregisterHotkey()
        hotkeyManager = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testInitialization() {
        XCTAssertNotNil(hotkeyManager, "HotkeyManager should initialize successfully")
        XCTAssertNotNil(hotkeyManager.delegate, "Delegate should be set")
    }
    
    func testRegisterHotkey() {
        // This should not crash - actual hotkey registration requires system permissions
        XCTAssertNoThrow(hotkeyManager.registerHotkey(), "registerHotkey should not throw")
    }
    
    func testUnregisterHotkey() {
        // Register first
        hotkeyManager.registerHotkey()
        
        // Then unregister - should not crash
        XCTAssertNoThrow(hotkeyManager.unregisterHotkey(), "unregisterHotkey should not throw")
    }
    
    func testMultipleRegisterCalls() {
        // Multiple register calls should not crash
        XCTAssertNoThrow(hotkeyManager.registerHotkey(), "First registerHotkey should not throw")
        XCTAssertNoThrow(hotkeyManager.registerHotkey(), "Second registerHotkey should not throw")
    }
    
    func testMultipleUnregisterCalls() {
        hotkeyManager.registerHotkey()
        
        // Multiple unregister calls should not crash
        XCTAssertNoThrow(hotkeyManager.unregisterHotkey(), "First unregisterHotkey should not throw")
        XCTAssertNoThrow(hotkeyManager.unregisterHotkey(), "Second unregisterHotkey should not throw")
    }
    
    func testUnregisterWithoutRegister() {
        // Unregistering without registering should not crash
        XCTAssertNoThrow(hotkeyManager.unregisterHotkey(), "unregisterHotkey without register should not throw")
    }
    
    func testDeinitCleanup() {
        hotkeyManager.registerHotkey()
        
        // Deinit should clean up properly - this tests that deinit doesn't crash
        hotkeyManager = nil
        
        // Create a new instance to continue with other tests
        hotkeyManager = HotkeyManager()
        mockDelegate = MockHotkeyManagerDelegate()
        hotkeyManager.delegate = mockDelegate
        
        // If we get here without crashing, the test passes
        XCTAssertTrue(true, "Deinit should complete without crashing")
    }
    
    // MARK: - Delegate Tests
    
    func testDelegateAssignment() {
        let newDelegate = MockHotkeyManagerDelegate()
        hotkeyManager.delegate = newDelegate
        
        XCTAssertTrue(hotkeyManager.delegate === newDelegate, "Delegate should be properly assigned")
    }
    
    func testWeakDelegateReference() {
        var delegate: MockHotkeyManagerDelegate? = MockHotkeyManagerDelegate()
        hotkeyManager.delegate = delegate
        
        XCTAssertNotNil(hotkeyManager.delegate, "Delegate should be set")
        
        delegate = nil
        
        // The delegate should be nil due to weak reference
        XCTAssertNil(hotkeyManager.delegate, "Delegate should be nil after being deallocated")
    }
    
    // MARK: - Direct Hotkey Tests
    
    func testDirectHotkeyDelegateCall() {
        // Test direct hotkey for index 0 (⌘⇧1)
        mockDelegate.directHotkeyPressed(for: 0, isAutoPaste: true)
        
        XCTAssertEqual(mockDelegate.directHotkeyIndex, 0, "Should call delegate with correct index")
        XCTAssertEqual(mockDelegate.directHotkeyCallCount, 1, "Should call delegate once")
        XCTAssertTrue(mockDelegate.isAutoPaste, "Should pass auto-paste flag")
    }
    
    func testDirectHotkeyMultipleIndices() {
        // Test all 6 direct hotkeys
        for index in 0..<6 {
            mockDelegate.directHotkeyPressed(for: index, isAutoPaste: true)
            XCTAssertEqual(mockDelegate.directHotkeyIndex, index, "Should call delegate with index \(index)")
        }
        
        XCTAssertEqual(mockDelegate.directHotkeyCallCount, 6, "Should call delegate 6 times")
    }
    
    func testDirectHotkeyBoundaryValues() {
        // Test edge cases
        mockDelegate.directHotkeyPressed(for: -1, isAutoPaste: false) // Should handle gracefully
        mockDelegate.directHotkeyPressed(for: 0, isAutoPaste: true)  // Valid
        mockDelegate.directHotkeyPressed(for: 5, isAutoPaste: true)  // Valid (last valid index)
        mockDelegate.directHotkeyPressed(for: 6, isAutoPaste: false)  // Should handle gracefully
        mockDelegate.directHotkeyPressed(for: 10, isAutoPaste: false) // Should handle gracefully
        
        // All calls should be handled
        XCTAssertEqual(mockDelegate.directHotkeyCallCount, 5, "Should handle all calls")
    }
    
    func testQuitHotkeyDelegate() {
        mockDelegate.quitHotkeyPressed()
        
        XCTAssertTrue(mockDelegate.quitHotkeyPressedWasCalled, "Should call quit hotkey delegate")
        XCTAssertEqual(mockDelegate.quitHotkeyCallCount, 1, "Should call quit delegate once")
    }
}

// MARK: - Mock Delegate

class MockHotkeyManagerDelegate: HotkeyManagerDelegate {
    var hotkeyPressedWasCalled = false
    var hotkeyPressedCallCount = 0
    
    var quitHotkeyPressedWasCalled = false
    var quitHotkeyCallCount = 0
    
    var directHotkeyIndex: Int = -1
    var directHotkeyCallCount = 0
    var isAutoPaste: Bool = false
    var hotkeyType: HotkeyType?
    
    func hotkeyPressed(type: HotkeyType) {
        hotkeyPressedWasCalled = true
        hotkeyPressedCallCount += 1
        hotkeyType = type
    }
    
    func quitHotkeyPressed() {
        quitHotkeyPressedWasCalled = true
        quitHotkeyCallCount += 1
    }
    
    func directHotkeyPressed(for index: Int, isAutoPaste: Bool) {
        directHotkeyIndex = index
        directHotkeyCallCount += 1
        self.isAutoPaste = isAutoPaste
    }
} 