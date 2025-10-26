// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolanaWalletAdapterKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "SolanaWalletAdapterKit",
            targets: ["SolanaWalletAdapterKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/The-SolShare-Team/SwiftBorsh", .upToNextMajor(from: "0.0.0")),
    ],
    targets: [
        .target(
            name: "SolanaWalletAdapterKit",
        ),
        .target(
            name: "RPC",
            dependencies: ["SwiftBorsh"]
        ),
        .testTarget(
            name: "SolanaWalletAdapterKitTests",
            dependencies: ["SolanaWalletAdapterKit"]
        ),
    ]
)
