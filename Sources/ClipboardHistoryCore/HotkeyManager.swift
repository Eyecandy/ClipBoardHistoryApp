import Foundation
import AppKit
import Carbon

public protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed(type: HotkeyType)
    func quitHotkeyPressed()
    func directHotkeyPressed(for index: Int, isAutoPaste: Bool) // For ⌘⌥1-6 with auto-paste flag
    func directHotkeyPreview(for index: Int) // Preview when key is held
    func directHotkeyPreviewEnded() // When preview ends
}

public enum HotkeyType {
    case showHistory
    case showPinned
}

public class HotkeyManager {
    public weak var delegate: HotkeyManagerDelegate?
    private var hotKeyRefs: [String: EventHotKeyRef] = [:]
    private var eventHandler: EventHandlerRef?
    private var hotkeySettings: HotkeySettings
    private var isUsingPinnedMode = false
    private var previewTimer: Timer?
    private var isPreviewActive = false
    
    public init() {
        hotkeySettings = HotkeySettings()
    }
    
    public func getHotkeySettings() -> HotkeySettings {
        return hotkeySettings
    }
    
    public func setUsingPinnedMode(_ enabled: Bool) {
        isUsingPinnedMode = enabled
    }
    
    public func isInPinnedMode() -> Bool {
        return isUsingPinnedMode
    }
    
    public func registerHotkey() {
        // Create event type for hotkey press
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // Install event handler
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                // This is called when our hotkey is pressed
                if let userData = userData {
                    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                    
                    // Get the hotkey ID to determine which hotkey was pressed
                    var hotKeyID = EventHotKeyID()
                    GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                    
                    DispatchQueue.main.async {
                        manager.handleHotkeyPressed(hotKeyID: hotKeyID)
                    }
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        
        if status != noErr {
            print("❌ Failed to install hotkey event handler: \(status)")
            return
        }
        
        // Register all configured hotkeys
        registerAllHotkeys()
    }
    
    private func handleHotkeyPressed(hotKeyID: EventHotKeyID) {
        switch hotKeyID.id {
        case 1: // Show History
            delegate?.hotkeyPressed(type: .showHistory)
            setUsingPinnedMode(false)
        case 2: // Show Pinned
            delegate?.hotkeyPressed(type: .showPinned)
            setUsingPinnedMode(true)
        case 10...15: // Direct hotkeys for clipboard items 1-6 (IDs 10-15)
            let index = Int(hotKeyID.id) - 10
            
            // Cancel any existing preview timer
            previewTimer?.invalidate()
            previewTimer = nil
            
            // Start preview with short delay
            previewTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.isPreviewActive = true
                self?.delegate?.directHotkeyPreview(for: index)
                
                                 // Auto-hide preview after 2 seconds and execute paste
                 DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                     if self?.isPreviewActive == true {
                         self?.isPreviewActive = false
                         self?.delegate?.directHotkeyPreviewEnded()
                         // Execute the paste after preview
                         self?.delegate?.directHotkeyPressed(for: index, isAutoPaste: true)
                     }
                 }
            }
        default:
            break
        }
    }
    
    private func registerAllHotkeys() {
        // Unregister existing hotkeys first
        unregisterAllHotkeys()
        
        // Register show history hotkey
        if let config = hotkeySettings.getConfig(for: "showHistory") {
            registerSingleHotkey(id: 1, config: config, name: "Show History")
        }
        
        // Register show pinned hotkey
        if let config = hotkeySettings.getConfig(for: "showPinned") {
            registerSingleHotkey(id: 2, config: config, name: "Show Pinned")
        }
        
        // Register direct hotkeys for items 1-6
        for i in 1...6 {
            if let config = hotkeySettings.getConfig(for: "directCopy\(i)") {
                registerSingleHotkey(id: UInt32(9 + i), config: config, name: "Direct Copy \(i)")
            }
        }
    }
    
    private func registerSingleHotkey(id: UInt32, config: HotkeyConfig, name: String) {
        let hotKeyID = EventHotKeyID(signature: fourCharCode("CBHK"), id: id)
        
        var hotKeyRef: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            config.keyCode,
            config.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if registerStatus == noErr, let ref = hotKeyRef {
            hotKeyRefs[config.id] = ref
            print("✅ Hotkey \(config.displayString) registered for \(name)")
        } else {
            print("❌ Failed to register hotkey \(config.displayString) for \(name): \(registerStatus)")
        }
    }
    
    public func updateHotkeys() {
        // Re-register all hotkeys with updated settings
        registerAllHotkeys()
    }
    
    public func unregisterHotkey() {
        unregisterAllHotkeys()
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    private func unregisterAllHotkeys() {
        for (_, hotKeyRef) in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
    }
    
    deinit {
        previewTimer?.invalidate()
        previewTimer = nil
        unregisterHotkey()
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    assert(string.count == 4)
    var code: FourCharCode = 0
    for char in string.utf8 {
        code = (code << 8) + FourCharCode(char)
    }
    return code
} 
