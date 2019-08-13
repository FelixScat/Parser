// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Parser",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "Parser",
            targets: ["Parser"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/thoughtbot/Runes", from: "5.0.0"),
        .package(url: "https://github.com/thoughtbot/Curry", from: "4.0.2"),
        .package(path: "../LLexer"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Parser",
            dependencies: ["LLexer", "Runes"]),
        .testTarget(
            name: "ParserTests",
            dependencies: ["Parser"]),
    ]
)
