// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardHistoryApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClipboardHistoryApp", targets: ["ClipboardHistoryApp"])
    ],
    targets: [
        .executableTarget(
            name: "ClipboardHistoryApp",
            dependencies: []
        )
    ]
) 