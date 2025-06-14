import SwiftUI
import HotKey

struct SettingsView: View {
    @StateObject private var shortcutManager = KeyboardShortcutManager.shared
    @State private var isRecordingShortcut = false
    @State private var tempKey: Key?
    @State private var tempModifiers: NSEvent.ModifierFlags = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Keyboard Shortcuts")
                .font(.title)
                .padding(.top)
            
            // Shortcut Recording Button
            Button(action: {
                isRecordingShortcut.toggle()
            }) {
                HStack {
                    Text("Paste History Shortcut:")
                    Spacer()
                    Text(shortcutDisplay)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(isRecordingShortcut ? Color.blue.opacity(0.1) : Color.clear)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .onKeyPress { press in
                if isRecordingShortcut {
                    if let key = keyEquivalentToHotKey(press.key) {
                        tempKey = key
                        tempModifiers = eventModifiersToNSEvent(press.modifiers)
                    }
                    return .handled
                }
                return .ignored
            }
            .onChange(of: tempKey) { newKey in
                if let key = newKey {
                    shortcutManager.saveShortcut(key: key, modifiers: tempModifiers)
                    isRecordingShortcut = false
                    tempKey = nil
                    tempModifiers = []
                }
            }
            
            // Instructions
            if isRecordingShortcut {
                Text("Press any key combination to set the shortcut")
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            
            Spacer()
        }
        .frame(width: 400, height: 200)
        .padding()
    }
    
    private var shortcutDisplay: String {
        if isRecordingShortcut {
            return "Press keys..."
        }
        
        let key = shortcutManager.currentKey
        let modifiers = shortcutManager.currentModifiers
        
        var display = ""
        if modifiers.contains(.command) { display += "⌘" }
        if modifiers.contains(.option) { display += "⌥" }
        if modifiers.contains(.control) { display += "⌃" }
        if modifiers.contains(.shift) { display += "⇧" }
        display += keyDisplay(key)
        return display.isEmpty ? "Not set" : display
    }
    
    private func keyEquivalentToHotKey(_ key: KeyEquivalent) -> Key? {
        switch key.character {
        case "a": return .a
        case "b": return .b
        case "c": return .c
        case "d": return .d
        case "e": return .e
        case "f": return .f
        case "g": return .g
        case "h": return .h
        case "i": return .i
        case "j": return .j
        case "k": return .k
        case "l": return .l
        case "m": return .m
        case "n": return .n
        case "o": return .o
        case "p": return .p
        case "q": return .q
        case "r": return .r
        case "s": return .s
        case "t": return .t
        case "u": return .u
        case "v": return .v
        case "w": return .w
        case "x": return .x
        case "y": return .y
        case "z": return .z
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        case "8": return .eight
        case "9": return .nine
        case "0": return .zero
        default: return nil
        }
    }
    
    private func eventModifiersToNSEvent(_ modifiers: EventModifiers) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers.contains(.command) { flags.insert(.command) }
        if modifiers.contains(.option) { flags.insert(.option) }
        if modifiers.contains(.control) { flags.insert(.control) }
        if modifiers.contains(.shift) { flags.insert(.shift) }
        return flags
    }
    
    private func keyDisplay(_ key: Key) -> String {
        switch key {
        case .return: return "↩"
        case .space: return "␣"
        // Add more special cases as needed
        default: return key.description.uppercased()
        }
    }
} 