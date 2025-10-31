// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolanaWalletAdapterKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "SolanaWalletAdapterKit",
            targets: ["SolanaWalletAdapterKit"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/The-SolShare-Team/SwiftBorsh", .upToNextMajor(from: "1.0.0")),
        .package(
            url: "https://github.com/The-SolShare-Team/Salkt.swift", .upToNextMajor(from: "0.0.0")),
        .package(
            url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git",
            .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "Salt",
            dependencies: [
                "Salkt.swift",
                .product(name: "TweetNacl", package: "tweetnacl-swiftwrap"),
            ]),
        .testTarget(name: "SaltTests", dependencies: ["Salt"]),
        .target(
            name: "SolanaWalletAdapterKit"),
        .testTarget(
            name: "SolanaWalletAdapterKitTests",
            dependencies: ["SolanaWalletAdapterKit"]),
        .target(
            name: "SolanaTransactions",
            dependencies: ["SwiftBorsh", "Salt"]),
        .testTarget(
            name: "SolanaTransactionsTests",
            dependencies: ["SolanaTransactions", "SwiftBorsh", "SolanaRPC"]),
        .target(
            name: "SolanaRPC",
            dependencies: ["SwiftBorsh", "SolanaTransactions"]),
        .testTarget(
            name: "SolanaRPCTests",
            dependencies: ["SolanaRPC"]),
    ]
)
