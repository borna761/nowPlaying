// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "NowPlaying",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "NowPlaying",
            targets: ["NowPlaying"]
        )
    ],
    targets: [
        .executableTarget(
            name: "NowPlaying",
            dependencies: [],
            path: ".",
            sources: [
                "NowPlayingApp.swift",
                "MediaControl.swift",
                "MenuController.swift"
            ]
        )
    ]
)
