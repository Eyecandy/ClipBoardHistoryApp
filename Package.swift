// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardHistoryApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ClipboardHistoryApp",
            targets: ["ClipboardHistoryApp"]
        ),
        .library(
            name: "ClipboardHistoryCore",
            targets: ["ClipboardHistoryCore"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here if needed
    ],
    targets: [
        .target(
            name: "ClipboardHistoryCore",
            dependencies: [],
            path: "Sources/ClipboardHistoryCore"
        ),
        .executableTarget(
            name: "ClipboardHistoryApp",
            dependencies: ["ClipboardHistoryCore"],
            path: "Sources/ClipboardHistoryApp"
        ),
        .testTarget(
            name: "ClipboardHistoryAppTests",
            dependencies: ["ClipboardHistoryCore"],
            path: "Tests/ClipboardHistoryAppTests"
        ),
    ]
) 