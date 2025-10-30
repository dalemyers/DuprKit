// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DuprKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DuprKit",
            targets: ["DuprKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/dalemyers/DictionaryCoder", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DuprKit",
            dependencies: ["DictionaryCoder"]
        ),
        .testTarget(
            name: "DuprKitTests",
            dependencies: ["DuprKit"]
        ),
    ]
)
