// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Kassandra",
    products: [
        .library(name: "Kassandra", targets: ["Kassandra"]),
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/BlueSSLService.git", from: "1.0.46")
    ],
    targets: [
        .target(name: "Kassandra", dependencies: ["SSLService"], exclude: ["Kassandra.xcodeproj", "README.md"]),
        .testTarget(name: "KassandraTests", dependencies: ["Kassandra"]),
    ],
    swiftLanguageVersions: [.v5]
)
