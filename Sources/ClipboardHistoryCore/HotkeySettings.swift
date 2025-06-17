import Foundation
import AppKit
import Carbon

public struct HotkeyConfig {
    public let id: String
    public let displayName: String
    public let defaultKeyCode: UInt32
    public let defaultModifiers: UInt32
    public var keyCode: UInt32
    public var modifiers: UInt32
    
    public init(id: String, displayName: String, defaultKeyCode: UInt32, defaultModifiers: UInt32) {
        self.id = id
        self.displayName = displayName
        self.defaultKeyCode = defaultKeyCode
        self.defaultModifiers = defaultModifiers
        self.keyCode = defaultKeyCode
        self.modifiers = defaultModifiers
    }
    
    public var displayString: String {
        var parts: [String] = []
        
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        
        let keyString = keyCodeToString(keyCode)
        parts.append(keyString)
        
        return parts.joined()
    }
}

public class HotkeySettings {
    private let settingsKey = "HotkeySettings"
    public private(set) var configs: [String: HotkeyConfig] = [:]
    
    public init() {
        setupDefaultConfigs()
        loadSettings()
    }
    
    private func setupDefaultConfigs() {
        configs = [
            "showHistory": HotkeyConfig(
                id: "showHistory",
                displayName: "Show Clipboard History",
                defaultKeyCode: 8, // C
                defaultModifiers: UInt32(cmdKey | shiftKey)
            ),
            "showPinned": HotkeyConfig(
                id: "showPinned",
                displayName: "Show Pinned Items",
                defaultKeyCode: 35, // P
                defaultModifiers: UInt32(cmdKey | shiftKey)
            ),
            "directCopy1": HotkeyConfig(
                id: "directCopy1",
                displayName: "Copy & Paste Item 1",
                defaultKeyCode: 18, // 1
                defaultModifiers: UInt32(cmdKey | optionKey)
            ),
            "directCopy2": HotkeyConfig(
                id: "directCopy2",
                displayName: "Copy & Paste Item 2",
                defaultKeyCode: 19, // 2
                defaultModifiers: UInt32(cmdKey | optionKey)
            ),
            "directCopy3": HotkeyConfig(
                id: "directCopy3",
                displayName: "Copy & Paste Item 3",
                defaultKeyCode: 20, // 3
                defaultModifiers: UInt32(cmdKey | optionKey)
            ),
            "directCopy4": HotkeyConfig(
                id: "directCopy4",
                displayName: "Copy & Paste Item 4",
                defaultKeyCode: 21, // 4
                defaultModifiers: UInt32(cmdKey | optionKey)
            ),
            "directCopy5": HotkeyConfig(
                id: "directCopy5",
                displayName: "Copy & Paste Item 5",
                defaultKeyCode: 23, // 5
                defaultModifiers: UInt32(cmdKey | optionKey)
            ),
            "directCopy6": HotkeyConfig(
                id: "directCopy6",
                displayName: "Copy & Paste Item 6",
                defaultKeyCode: 22, // 6
                defaultModifiers: UInt32(cmdKey | optionKey)
            ),
            "directCopy7": HotkeyConfig(
                id: "directCopy7",
                displayName: "Copy & Paste Item 7",
                defaultKeyCode: 26, // 7
                defaultModifiers: UInt32(cmdKey | optionKey)
            ),
            "directCopy8": HotkeyConfig(
                id: "directCopy8",
                displayName: "Copy & Paste Item 8",
                defaultKeyCode: 28, // 8
                defaultModifiers: UInt32(cmdKey | optionKey)
            ),
            "directCopy9": HotkeyConfig(
                id: "directCopy9",
                displayName: "Copy & Paste Item 9",
                defaultKeyCode: 25, // 9
                defaultModifiers: UInt32(cmdKey | optionKey)
            )
        ]
    }
    
    public func getConfig(for id: String) -> HotkeyConfig? {
        return configs[id]
    }
    
    public func updateConfig(id: String, keyCode: UInt32, modifiers: UInt32) {
        guard var config = configs[id] else { return }
        config.keyCode = keyCode
        config.modifiers = modifiers
        configs[id] = config
        saveSettings()
    }
    
    public func resetToDefaults() {
        for (id, config) in configs {
            var resetConfig = config
            resetConfig.keyCode = config.defaultKeyCode
            resetConfig.modifiers = config.defaultModifiers
            configs[id] = resetConfig
        }
        saveSettings()
    }
    
    public func getAllConfigs() -> [HotkeyConfig] {
        return Array(configs.values).sorted { $0.displayName < $1.displayName }
    }
    
    private func saveSettings() {
        var settingsDict: [String: [String: UInt32]] = [:]
        for (id, config) in configs {
            settingsDict[id] = [
                "keyCode": config.keyCode,
                "modifiers": config.modifiers
            ]
        }
        UserDefaults.standard.set(settingsDict, forKey: settingsKey)
        UserDefaults.standard.synchronize()
    }
    
    private func loadSettings() {
        guard let settingsDict = UserDefaults.standard.dictionary(forKey: settingsKey) as? [String: [String: UInt32]] else {
            return
        }
        
        for (id, values) in settingsDict {
            guard var config = configs[id],
                  let keyCode = values["keyCode"],
                  let modifiers = values["modifiers"] else {
                continue
            }
            config.keyCode = keyCode
            config.modifiers = modifiers
            configs[id] = config
        }
    }
}

private func keyCodeToString(_ keyCode: UInt32) -> String {
    switch keyCode {
    case 0: return "A"
    case 1: return "S"
    case 2: return "D"
    case 3: return "F"
    case 4: return "H"
    case 5: return "G"
    case 6: return "Z"
    case 7: return "X"
    case 8: return "C"
    case 9: return "V"
    case 11: return "B"
    case 12: return "Q"
    case 13: return "W"
    case 14: return "E"
    case 15: return "R"
    case 16: return "Y"
    case 17: return "T"
    case 18: return "1"
    case 19: return "2"
    case 20: return "3"
    case 21: return "4"
    case 22: return "6"
    case 23: return "5"
    case 24: return "="
    case 25: return "9"
    case 26: return "7"
    case 27: return "-"
    case 28: return "8"
    case 29: return "0"
    case 30: return "]"
    case 31: return "O"
    case 32: return "U"
    case 33: return "["
    case 34: return "I"
    case 35: return "P"
    case 36: return "↩"
    case 37: return "L"
    case 38: return "J"
    case 39: return "'"
    case 40: return "K"
    case 41: return ";"
    case 42: return "\\"
    case 43: return ","
    case 44: return "/"
    case 45: return "N"
    case 46: return "M"
    case 47: return "."
    case 48: return "⇥"
    case 49: return "Space"
    case 50: return "`"
    case 51: return "⌫"
    case 53: return "⎋"
    case 123: return "←"
    case 124: return "→"
    case 125: return "↓"
    case 126: return "↑"
    default: return "Key\(keyCode)"
    }
} 