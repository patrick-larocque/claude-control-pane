// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClaudeControlPane",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeControlPane",
            path: "Sources"
        )
    ]
)
