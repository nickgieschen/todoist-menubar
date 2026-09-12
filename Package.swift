// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TodoistMenubar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "TodoistMenubar", path: "Sources/TodoistMenubar")
    ]
)
