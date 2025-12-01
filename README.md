# SolanaWalletAdapterKit

Swift library for integrating Solana wallets into iOS and macOS apps via deeplinks.

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2014%2B%20|%20macOS%2011%2B-blue.svg)](https://developer.apple.com)

## Overview

**SolanaWalletAdapterKit** simplifies wallet connections, transaction signing, and message signing while supporting multiple wallet providers. It provides a type-safe transaction builder, encrypted deeplink communication, persistent sessions via Keychain, built-in programs, and async/await RPC client access.

### Key Features

- Multi-wallet support: Phantom, Solflare, Backpack
- Type-safe transaction builder with DSL
- Encrypted deeplink communication (Diffie-Hellman)
- Persistent sessions via Keychain
- Built-in programs: System, Token, AssociatedToken, Memo
- Async/await RPC client for Solana

### Supported Platforms

- iOS 14.0+
- macOS 11.0+
- Swift 6.2+
- Xcode 16.0+

## Installation

Add the package via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/The-SolShare-Team/SolanaWalletAdapterKit.git", from: "1.0.0")
]
```
### Import in your Swift project:
```swift
import SolanaWalletAdapterKit
import SolanaRPC
import SolanaTransactions
```

## Quick Start

Add to Info.plist in your app:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
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

Register your app's callback scheme in your app's main Swift file and add a URL handler:

**SwiftUI:**

```swift
import SwiftUI
import SolanaWalletAdapterKit

@main
struct YourApp: App {
    init() {
        // Register callback Scheme
        SolanaWalletAdapter.registerCallbackScheme("yourapp")
    }

    var body: some Scene {
        WindowGroup {
            
            // Add a URL handler to your ContentView:
            ContentView()
                .onOpenURL { url in
                    if SolanaWalletAdapter.handleOnOpenURL(url) { return }
                }
        }
    }
    ...
```

**UIKit:**
```swift
import UIKit
import SolanaWalletAdapterKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register callback scheme 
        SolanaWalletAdapter.registerCallbackScheme("yourapp")
        return true
    }

    // Add a URL handler
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return SolanaWalletAdapter.handleOnOpenURL(url) 
    }

    ...
}
```

## Common Operations

### Build, Sign, and Send a Transaction

```swift
import SolanaWalletAdapterKit
import SolanaRPC

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

### Token Transfer Transaction

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
print(result.signature)
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

## API References
Full API references can be found [here](https://swak.solshare.team/documentation/) 

## Examples

A demo application can be found in the accompanying repository [DemoAppSolanaWalletAdapterKit](https://github.com/The-SolShare-Team/DemoAppSolanaWalletAdapterKit) that showcases core functionality.


### License

See repository license

