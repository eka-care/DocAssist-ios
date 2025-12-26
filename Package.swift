// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DocAssist-ios",
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
    .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
    // Medical Record
    .package(url: "git@github.com:eka-care/EkaMedicalRecordsUI.git",  branch: "1.4.0"),
    // Mixpanel
    .package(url: "https://github.com/mixpanel/mixpanel-swift", from: "3.2.5"),
    // EkaPDFMaker
    .package(url: "git@github.com:eka-care/EkaPDFMaker.git", branch: "main")
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "ChatBotAiPackage",
      dependencies: [
        // MarkdownUI
        .product(name: "MarkdownUI", package: "swift-markdown-ui"),
        // Medical Record
        .product(name: "EkaMedicalRecordsUI", package: "EkaMedicalRecordsUI"),
        // Mixpanel
        .product(name: "Mixpanel", package: "mixpanel-swift"),
        // PdfRender
        .product(name: "EkaPDFMaker", package: "EkaPDFMaker")
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
