// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SolanaWalletAdapterKit",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(
            name: "SolanaWalletAdapterKit",
            targets: ["SolanaWalletAdapterKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/The-SolShare-Team/web3-core.swift", .upToNextMajor(from: "0.0.0")),
        .package(url: "https://github.com/The-SolShare-Team/rpc-core.swift", .upToNextMajor(from: "0.0.0")),
    ],
    targets: [
        .target(
            name: "SolanaWalletAdapterKit",
            dependencies: [
                .product(name: "web3_solana", package: "web3-core.swift"),
                .product(name: "rpc_solana", package: "rpc-core.swift")
            ]
        ),
        .testTarget(
            name: "SolanaWalletAdapterKitTests",
            dependencies: ["SolanaWalletAdapterKit"]
        ),
    ]
)
