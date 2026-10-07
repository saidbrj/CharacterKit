// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CharacterKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "CharacterKit", targets: ["CharacterKit"])
    ],
    targets: [
        .target(
            name: "CharacterKit",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CharacterKitTests",
            dependencies: ["CharacterKit"]
        )
    ]
)
