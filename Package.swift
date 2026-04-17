// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CCApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "CCApp",
            path: "Sources/CCApp"
        )
    ]
)
