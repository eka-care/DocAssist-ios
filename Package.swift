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
    // MarkdownUI package dependency
    .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.2"),
    // FireBase package dependency
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.1"),
   // Lottie dependency
    .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.5.1")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "ChatBotAiPackage",
      dependencies: [
        // MarkdownUI
        .product(name: "MarkdownUI", package: "swift-markdown-ui"),
        // FireBase
        .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
        // Lottie dependency
        .product(name: "Lottie", package: "lottie-ios")
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
