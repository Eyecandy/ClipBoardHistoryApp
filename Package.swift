// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClipboardHistoryApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ClipboardHistoryApp",
            targets: ["ClipboardHistoryApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "ClipboardHistoryApp",
            dependencies: ["HotKey"],
            path: "ClipboardHistoryApp/Sources",
            exclude: ["Resources/generate_icon.swift"]
        ),
        .testTarget(
            name: "ClipboardHistoryAppTests",
            dependencies: ["ClipboardHistoryApp"],
            path: "ClipboardHistoryApp/Tests"
        )
    ]
) 