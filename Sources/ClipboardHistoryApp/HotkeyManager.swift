import Foundation
import AppKit
import Carbon

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed()
}

class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate?
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    func registerHotkey() {
        print("Registering hotkey using Carbon API...")
        
        // Create event type for hotkey
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // Install event handler
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                // This is called when our hotkey is pressed
                if let userData = userData {
                    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                    print("🎯 CARBON HOTKEY DETECTED!")
                    DispatchQueue.main.async {
                        manager.delegate?.hotkeyPressed()
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
            print("❌ Failed to install event handler: \(status)")
            return
        }
        
        // Register the hotkey (Cmd+Shift+V)
        let hotKeyID = EventHotKeyID(signature: fourCharCode("CBHK"), id: 1)
        let keyCode: UInt32 = 9 // V key
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if registerStatus == noErr {
            print("✅ Hotkey Cmd+Shift+V registered successfully!")
        } else {
            print("❌ Failed to register hotkey: \(registerStatus)")
        }
    }
    
    func unregisterHotkey() {
        print("Unregistering hotkey...")
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
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