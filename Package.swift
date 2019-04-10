// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kassandra",
    products: [
        .library(name: "Kassandra", targets: ["Kassandra"]),
    ],
    dependencies: [
        .package(url: "https://github.com/IBM-Swift/BlueSSLService.git", from: "1.0.45")
    ],
    targets: [
        .target(name: "Kassandra", dependencies: ["SSLService"]),
        .testTarget(name: "KassandraTests", dependencies: ["Kassandra"]),
    ]
)
