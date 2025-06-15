import Foundation
import AppKit
import Carbon

public protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed()
    func quitHotkeyPressed()
    func directHotkeyPressed(for index: Int) // For ⌘⇧1-6
}

public class HotkeyManager {
    public weak var delegate: HotkeyManagerDelegate?
    private var hotKeyRef: EventHotKeyRef?
    private var quitHotKeyRef: EventHotKeyRef?
    private var directHotKeyRefs: [EventHotKeyRef?] = Array(repeating: nil, count: 6) // For ⌘⇧1-6
    private var eventHandler: EventHandlerRef?
    
    public init() {}
    
    public func registerHotkey() {
        // Create event type for hotkey
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
                        if hotKeyID.id == 1 {
                            manager.delegate?.hotkeyPressed()
                        } else if hotKeyID.id == 2 {
                            manager.delegate?.quitHotkeyPressed()
                        } else if hotKeyID.id >= 10 && hotKeyID.id <= 15 {
                            // Direct hotkeys for clipboard items 1-6 (IDs 10-15)
                            let index = Int(hotKeyID.id) - 10
                            manager.delegate?.directHotkeyPressed(for: index)
                        }
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
        
        // Register the hotkey (Cmd+Shift+C)
        let hotKeyID = EventHotKeyID(signature: fourCharCode("CBHK"), id: 1)
        let keyCode: UInt32 = 8 // C key
        let modifiers = UInt32(cmdKey | shiftKey)
        
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if registerStatus == noErr {
            print("✅ Hotkey ⌘⇧C registered")
        } else {
            print("❌ Failed to register hotkey: \(registerStatus)")
        }
        
        // Register direct hotkeys for clipboard items 1-6 (⌘⇧1-6)
        registerDirectHotkeys()
        
        // TODO: Re-enable quit hotkey after fixing crash
        // Temporarily disabled due to crash issues
    }
    
    private func registerDirectHotkeys() {
        // Key codes for numbers 1-6
        let keyCodes: [UInt32] = [18, 19, 20, 21, 23, 22] // 1, 2, 3, 4, 5, 6
        let modifiers = UInt32(cmdKey | shiftKey)
        
        for i in 0..<6 {
            let hotKeyID = EventHotKeyID(signature: fourCharCode("CBHK"), id: UInt32(10 + i)) // IDs 10-15
            let keyCode = keyCodes[i]
            
            var hotKeyRef: EventHotKeyRef?
            let registerStatus = RegisterEventHotKey(
                keyCode,
                modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            
            if registerStatus == noErr {
                directHotKeyRefs[i] = hotKeyRef
                print("✅ Direct hotkey ⌘⇧\(i + 1) registered")
            } else {
                print("❌ Failed to register direct hotkey ⌘⇧\(i + 1): \(registerStatus)")
            }
        }
    }
    
    public func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let quitHotKeyRef = quitHotKeyRef {
            UnregisterEventHotKey(quitHotKeyRef)
            self.quitHotKeyRef = nil
        }
        
        // Unregister direct hotkeys
        for i in 0..<directHotKeyRefs.count {
            if let hotKeyRef = directHotKeyRefs[i] {
                UnregisterEventHotKey(hotKeyRef)
                directHotKeyRefs[i] = nil
            }
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    deinit {
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
