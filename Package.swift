// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AdaptiveStack",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AdaptiveStack", targets: ["AdaptiveStack"]),
    ],
    targets: [
        .target(name: "AdaptiveStack"),
        .testTarget(name: "AdaptiveStackTests", dependencies: ["AdaptiveStack"]),
    ]
)
