// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Lightning",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .macCatalyst(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Lightning",
            targets: ["Lightning"]),
    ],
    dependencies: [
        .package(url: "https://github.com/lightningdevkit/ldk-swift/", exact: "0.0.110"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Lightning",
            dependencies: [
                "CryptoSwift",
                .product(name: "LightningDevKit", package: "ldk-swift"),
            ]),
        .testTarget(
            name: "LightningTests",
            dependencies: ["Lightning"]),
    ]
)
