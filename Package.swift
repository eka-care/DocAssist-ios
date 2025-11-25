// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DocAssist-ios",
  platforms: [
    .iOS(.v17)
  ],
  products: [
    .library(
      name: "ChatBotAiPackage",
      targets: ["ChatBotAiPackage"]),
  ],
  dependencies: [
    .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.1"),
    .package(url: "git@github.com:eka-care/EkaMedicalRecordsUI.git", branch: "testsshfix"),
    .package(url: "https://github.com/mixpanel/mixpanel-swift", from: "3.2.5"),
    .package(url: "git@github.com:eka-care/EkaVoiceToRx.git", branch: "main"),
    .package(url: "git@github.com:eka-care/EkaPDFMaker.git", branch: "main")
  ],
  targets: [
    .target(
      name: "ChatBotAiPackage",
      dependencies: [
        .product(name: "MarkdownUI", package: "swift-markdown-ui"),
        .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
        .product(name: "EkaMedicalRecordsUI", package: "EkaMedicalRecordsUI"),
        .product(name: "Mixpanel", package: "mixpanel-swift"),
        .product(name: "EkaVoiceToRx", package: "EkaVoiceToRx"),
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
