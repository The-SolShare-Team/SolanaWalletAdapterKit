// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolanaWalletAdapterKit",
    platforms: [
        .iOS(.v18),
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
            url: "https://github.com/The-SolShare-Team/SwiftBorsh",
            .upToNextMajor(from: "0.0.1")),
        .package(
            url: "https://github.com/The-SolShare-Team/Salkt.swift",
            .upToNextMajor(from: "0.0.0")),
        .package(
            url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap.git",
            .upToNextMajor(from: "1.0.0")),
        .package(
            url: "https://github.com/apple/swift-collections.git",
            .upToNextMajor(from: "1.0.0")),
        .package(
            url: "https://github.com/auth0/SimpleKeychain.git",
            .upToNextMajor(from: "1.0.0")),
        .package(
            url: "https://github.com/swiftlang/swift-docc-plugin",
            .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        .target(name: "Base58"),
        .testTarget(name: "Base58Tests", dependencies: ["Base58"]),

        .target(
            name: "Salt",
            dependencies: [
                "Salkt.swift",
                .product(name: "TweetNacl", package: "tweetnacl-swiftwrap"),
            ]),
        .testTarget(name: "SaltTests", dependencies: ["Salt", "Base58"]),

        .target(
            name: "SolanaRPC",
            dependencies: ["SwiftBorsh", "SolanaTransactions"]),
        .testTarget(
            name: "SolanaRPCTests",
            dependencies: ["SolanaRPC"]),

        .target(
            name: "SolanaTransactions",
            dependencies: [
                "Base58",
                "SwiftBorsh",
                "Salt",
                .product(name: "Collections", package: "swift-collections"),
            ]),
        .testTarget(
            name: "SolanaTransactionsTests",
            dependencies: ["SolanaTransactions", "SwiftBorsh", "SolanaRPC"]),

        .target(
            name: "SolanaWalletAdapterKit",
            dependencies: [
                "Base58",
                "SimpleKeychain",
                "SolanaRPC",
                "Salt",
                "SolanaTransactions",
            ]),
        .testTarget(
            name: "SolanaWalletAdapterKitTests",
            dependencies: ["SolanaWalletAdapterKit"]),
    ]
)
