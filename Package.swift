// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ChatBotAiPackage",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "ChatBotAiPackage",
      targets: ["ChatBotAiPackage"]),
  ],
  dependencies: [
    // Add MarkdownUI package dependency
    .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.2")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "ChatBotAiPackage",
      dependencies: [
        // Add MarkdownUI as a dependency to this target
        .product(name: "MarkdownUI", package: "swift-markdown-ui")
      ],
      resources: [
        .process("Resources")
      ]),
    .testTarget(
      name: "ChatBotAiPackageTests",
      dependencies: ["ChatBotAiPackage"]
    ),
  ]
)
