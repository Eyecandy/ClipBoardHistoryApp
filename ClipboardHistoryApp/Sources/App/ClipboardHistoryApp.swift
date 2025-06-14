import SwiftUI
import AppKit

@main
struct ClipboardHistoryApp: App {
    @StateObject private var clipboardManager = ClipboardManager.shared
    @State private var showSettings = false
    
    var body: some Scene {
        MenuBarExtra("Clipboard History", systemImage: "doc.on.clipboard") {
            VStack {
                ContentView()
                    .environmentObject(clipboardManager)
                
                Divider()
                
                Button(action: {
                    showSettings.toggle()
                }) {
                    Label("Settings", systemImage: "gear")
                }
                .buttonStyle(.plain)
            }
        }
        .menuBarExtraStyle(.window)
        
        Window("Settings", id: "settings") {
            SettingsView()
        }
        .defaultSize(width: 400, height: 200)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
} 