import XCTest
import Foundation
import Carbon.HIToolbox
@testable import ClipboardHistoryCore

final class HotkeySettingsTests: XCTestCase {
    var hotkeySettings: HotkeySettings!
    
    override func setUp() {
        super.setUp()
        hotkeySettings = HotkeySettings()
        
        // Clear any existing settings
        UserDefaults.standard.removeObject(forKey: "HotkeySettings")
    }
    
    override func tearDown() {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "HotkeySettings")
        hotkeySettings = nil
        super.tearDown()
    }
    
    func testDefaultConfigurations() {
        let configs = hotkeySettings.getAllConfigs()
        
        XCTAssertEqual(configs.count, 11, "Should have 11 default hotkey configurations")
        
        // Check if all expected configs exist
        let configIds = configs.map { $0.id }
        XCTAssertTrue(configIds.contains("showHistory"))
        XCTAssertTrue(configIds.contains("showPinned"))
        XCTAssertTrue(configIds.contains("directCopy1"))
        XCTAssertTrue(configIds.contains("directCopy2"))
        XCTAssertTrue(configIds.contains("directCopy3"))
        XCTAssertTrue(configIds.contains("directCopy4"))
        XCTAssertTrue(configIds.contains("directCopy5"))
        XCTAssertTrue(configIds.contains("directCopy6"))
        XCTAssertTrue(configIds.contains("directCopy7"))
        XCTAssertTrue(configIds.contains("directCopy8"))
        XCTAssertTrue(configIds.contains("directCopy9"))
    }
    
    func testShowHistoryDefaultConfig() {
        guard let config = hotkeySettings.getConfig(for: "showHistory") else {
            XCTFail("showHistory config should exist")
            return
        }
        
        XCTAssertEqual(config.id, "showHistory")
        XCTAssertEqual(config.displayName, "Show Clipboard History")
        XCTAssertEqual(config.defaultKeyCode, 8) // C key
        XCTAssertEqual(config.defaultModifiers, UInt32(cmdKey | shiftKey))
        XCTAssertEqual(config.keyCode, 8)
        XCTAssertEqual(config.modifiers, UInt32(cmdKey | shiftKey))
    }
    
    func testShowPinnedDefaultConfig() {
        guard let config = hotkeySettings.getConfig(for: "showPinned") else {
            XCTFail("showPinned config should exist")
            return
        }
        
        XCTAssertEqual(config.id, "showPinned")
        XCTAssertEqual(config.displayName, "Show Pinned Items")
        XCTAssertEqual(config.defaultKeyCode, 35) // P key
        XCTAssertEqual(config.defaultModifiers, UInt32(cmdKey | shiftKey))
    }
    
    func testDirectCopyConfigs() {
        for i in 1...9 {
            guard let config = hotkeySettings.getConfig(for: "directCopy\(i)") else {
                XCTFail("directCopy\(i) config should exist")
                continue
            }
            
            XCTAssertEqual(config.id, "directCopy\(i)")
            XCTAssertEqual(config.displayName, "Copy & Paste Item \(i)")
            XCTAssertEqual(config.defaultModifiers, UInt32(cmdKey | optionKey))
        }
    }
    
    func testDisplayString() {
        guard let config = hotkeySettings.getConfig(for: "showHistory") else {
            XCTFail("showHistory config should exist")
            return
        }
        
        let displayString = config.displayString
        XCTAssertTrue(displayString.contains("⌘"), "Display string should contain command symbol")
        XCTAssertTrue(displayString.contains("⇧"), "Display string should contain shift symbol")
        XCTAssertTrue(displayString.contains("C"), "Display string should contain C key")
    }
    
    func testUpdateConfig() {
        let newKeyCode: UInt32 = 13 // W key
        let newModifiers: UInt32 = UInt32(cmdKey | controlKey)
        
        hotkeySettings.updateConfig(id: "showHistory", keyCode: newKeyCode, modifiers: newModifiers)
        
        guard let updatedConfig = hotkeySettings.getConfig(for: "showHistory") else {
            XCTFail("showHistory config should exist after update")
            return
        }
        
        XCTAssertEqual(updatedConfig.keyCode, newKeyCode)
        XCTAssertEqual(updatedConfig.modifiers, newModifiers)
        
        // Default values should remain unchanged
        XCTAssertEqual(updatedConfig.defaultKeyCode, 8)
        XCTAssertEqual(updatedConfig.defaultModifiers, UInt32(cmdKey | shiftKey))
    }
    
    func testUpdateNonExistentConfig() {
        // This should not crash
        hotkeySettings.updateConfig(id: "nonExistent", keyCode: 10, modifiers: 100)
        
        let config = hotkeySettings.getConfig(for: "nonExistent")
        XCTAssertNil(config, "Non-existent config should remain nil")
    }
    
    func testResetToDefaults() {
        // First, modify some configs
        hotkeySettings.updateConfig(id: "showHistory", keyCode: 13, modifiers: UInt32(cmdKey | controlKey))
        hotkeySettings.updateConfig(id: "showPinned", keyCode: 14, modifiers: UInt32(cmdKey | controlKey))
        
        // Reset to defaults
        hotkeySettings.resetToDefaults()
        
        // Check that configs are back to defaults
        guard let historyConfig = hotkeySettings.getConfig(for: "showHistory"),
              let pinnedConfig = hotkeySettings.getConfig(for: "showPinned") else {
            XCTFail("Configs should exist after reset")
            return
        }
        
        XCTAssertEqual(historyConfig.keyCode, historyConfig.defaultKeyCode)
        XCTAssertEqual(historyConfig.modifiers, historyConfig.defaultModifiers)
        XCTAssertEqual(pinnedConfig.keyCode, pinnedConfig.defaultKeyCode)
        XCTAssertEqual(pinnedConfig.modifiers, pinnedConfig.defaultModifiers)
    }
    
    func testPersistence() {
        // Update a config
        let newKeyCode: UInt32 = 15 // R key
        let newModifiers: UInt32 = UInt32(cmdKey | optionKey | shiftKey)
        
        hotkeySettings.updateConfig(id: "showHistory", keyCode: newKeyCode, modifiers: newModifiers)
        
        // Create a new instance (simulating app restart)
        let newHotkeySettings = HotkeySettings()
        
        guard let persistedConfig = newHotkeySettings.getConfig(for: "showHistory") else {
            XCTFail("showHistory config should persist")
            return
        }
        
        XCTAssertEqual(persistedConfig.keyCode, newKeyCode)
        XCTAssertEqual(persistedConfig.modifiers, newModifiers)
    }
    
    func testGetAllConfigsSorted() {
        let configs = hotkeySettings.getAllConfigs()
        
        // Should be sorted by display name
        for i in 0..<configs.count-1 {
            XCTAssertLessThanOrEqual(configs[i].displayName, configs[i+1].displayName,
                                   "Configs should be sorted by display name")
        }
    }
    
    func testDirectCopyKeyMapping() {
        // Test that direct copy configs have correct key mappings
        let expectedKeyCodes: [UInt32] = [18, 19, 20, 21, 23, 22, 26, 28, 25] // 1, 2, 3, 4, 5, 6, 7, 8, 9
        
        for i in 1...9 {
            guard let config = hotkeySettings.getConfig(for: "directCopy\(i)") else {
                XCTFail("directCopy\(i) config should exist")
                continue
            }
            
            XCTAssertEqual(config.defaultKeyCode, expectedKeyCodes[i-1],
                         "directCopy\(i) should have correct default key code")
        }
    }
    
    func testModifierFlags() {
        // Test that modifier flags are correctly set
        guard let historyConfig = hotkeySettings.getConfig(for: "showHistory"),
              let pinnedConfig = hotkeySettings.getConfig(for: "showPinned"),
              let directConfig = hotkeySettings.getConfig(for: "directCopy1") else {
            XCTFail("Configs should exist")
            return
        }
        
        // History and pinned should use Cmd+Shift
        XCTAssertEqual(historyConfig.defaultModifiers, UInt32(cmdKey | shiftKey))
        XCTAssertEqual(pinnedConfig.defaultModifiers, UInt32(cmdKey | shiftKey))
        
        // Direct copy should use Cmd+Option
        XCTAssertEqual(directConfig.defaultModifiers, UInt32(cmdKey | optionKey))
    }
    
    func testDisplayStringWithDifferentModifiers() {
        // Test display string with different modifier combinations
        hotkeySettings.updateConfig(id: "showHistory", 
                                  keyCode: 8, 
                                  modifiers: UInt32(cmdKey | optionKey | controlKey | shiftKey))
        
        guard let config = hotkeySettings.getConfig(for: "showHistory") else {
            XCTFail("Config should exist")
            return
        }
        
        let displayString = config.displayString
        XCTAssertTrue(displayString.contains("⌘"), "Should contain command")
        XCTAssertTrue(displayString.contains("⌥"), "Should contain option")  
        XCTAssertTrue(displayString.contains("⌃"), "Should contain control")
        XCTAssertTrue(displayString.contains("⇧"), "Should contain shift")
        XCTAssertTrue(displayString.contains("C"), "Should contain key")
    }
} 