# SolanaWalletAdapterKit

Swift library for integrating Solana wallets into iOS and macOS apps via deeplinks.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2014%2B%20|%20macOS%2011%2B-blue.svg)](https://developer.apple.com)

## Features

- Multi-wallet support (Phantom, Solflare, Backpack)
- Type-safe transaction builder with DSL
- Encrypted deeplink communication (Diffie-Hellman)
- Persistent sessions via Keychain
- Built-in programs (System, Token, AssociatedToken, Memo)
- RPC client with async/await

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/The-SolShare-Team/SolanaWalletAdapterKit.git", from: "1.0.0")
]
```

## Quick Start

```swift
import SolanaWalletAdapterKit

// Register callback scheme
SolanaWalletAdapter.registerCallbackScheme("myapp")

// Create wallet
let appIdentity = AppIdentity(name: "My App", url: URL(string: "https://myapp.com")!, icon: "icon.png")
var wallet = PhantomWallet(for: appIdentity, cluster: .mainnet)

// Connect
try await wallet.connect()

// Build and send transaction
let rpc = SolanaRPCClient(endpoint: .mainnet)
let blockhash = try await rpc.getLatestBlockhash().blockhash

let tx = try Transaction(feePayer: wallet.publicKey!, blockhash: blockhash) {
    SystemProgram.transfer(from: wallet.publicKey!, to: "Recipient...", lamports: 1_000_000)
}

let result = try await wallet.signAndSendTransaction(transaction: tx)
```

### Handle Callbacks

**SwiftUI:**
```swift
.onOpenURL { url in
    SolanaWalletAdapter.handleOnOpenURL(url)
}
```

**UIKit:**
```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    SolanaWalletAdapter.handleOnOpenURL(url)
    return true
}
```

### URL Scheme Setup

Add to Info.plist:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>phantom</string>
    <string>solflare</string>
    <string>backpack</string>
</array>
```

## Common Operations

### Token Transfer

```swift
let tx = try Transaction(feePayer: wallet.publicKey!, blockhash: blockhash) {
    TokenProgram.transfer(
        source: sourceTokenAccount,
        destination: destTokenAccount,
        authority: wallet.publicKey!,
        amount: 100_000_000
    )
}
```

### Sign Message

```swift
let message = "Sign this".data(using: .utf8)!
let result = try await wallet.signMessage(message: message, display: .utf8)
```

### Persistent Sessions

```swift
let manager = WalletConnectionManager(
    availableWallets: [PhantomWallet.self, SolflareWallet.self],
    storage: KeychainStorage()
)

// Recover saved connections
try await manager.recoverWallets()

// Connect and save
try await manager.pair(PhantomWallet.self, for: appIdentity, cluster: .mainnet)
```

## Documentation

- [Getting Started](docs/GettingStarted.md) - Setup and first integration
- [API Reference](docs/API.md) - Complete API documentation
- [Transactions](docs/Transactions.md) - Transaction building guide
- [Examples](docs/Examples.md) - Code examples
- [Architecture](docs/Architecture.md) - Design and internals

## Requirements

- iOS 14.0+ / macOS 11.0+
- Swift 6.2+
- Xcode 16.0+

## License

See repository license.
