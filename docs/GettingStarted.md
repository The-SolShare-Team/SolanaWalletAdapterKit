# Getting Started with SolanaWalletAdapterKit

This guide will walk you through integrating SolanaWalletAdapterKit into your iOS or macOS application, from installation to building your first Solana transaction.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Setup](#project-setup)
- [Your First Connection](#your-first-connection)
- [Building Transactions](#building-transactions)
- [Managing Persistent Sessions](#managing-persistent-sessions)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

- **Xcode 16.0+** installed
- **iOS 14.0+** or **macOS 11.0+** as your deployment target
- **Swift 6.2+** configured in your project
- A Solana wallet app installed on your device (Phantom, Solflare, or Backpack)
- Basic understanding of Swift async/await

## Installation

### Swift Package Manager

1. In Xcode, select **File > Add Package Dependencies**
2. Enter the repository URL:
   ```
   https://github.com/The-SolShare-Team/SolanaWalletAdapterKit.git
   ```
3. Select the version rule (recommended: "Up to Next Major Version")
4. Click **Add Package**
5. Select the `SolanaWalletAdapterKit` product and click **Add Package**

### Package.swift

If you're building a Swift package, add SolanaWalletAdapterKit to your dependencies:

```swift
dependencies: [
    .package(
        url: "https://github.com/The-SolShare-Team/SolanaWalletAdapterKit.git",
        from: "1.0.0"
    )
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["SolanaWalletAdapterKit"]
    )
]
```

## Project Setup

### Step 1: Register a Custom URL Scheme

SolanaWalletAdapterKit uses deeplinks to communicate with wallet apps. You need to register a custom URL scheme for callbacks.

#### In Xcode:

1. Select your project in the navigator
2. Select your app target
3. Go to the **Info** tab
4. Expand **URL Types**
5. Click **+** to add a new URL type
6. Set the following:
   - **Identifier**: `com.yourcompany.yourapp.walletcallback`
   - **URL Schemes**: `yourapp` (use your app's unique identifier)
   - **Role**: Editor

#### In Info.plist:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp.walletcallback</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

### Step 2: Add Wallet URL Schemes (iOS Only)

To check if wallet apps are installed, add their URL schemes to `LSApplicationQueriesSchemes`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>phantom</string>
    <string>solflare</string>
    <string>backpack</string>
</array>
```

### Step 3: Initialize SolanaWalletAdapter

Register your callback scheme when your app launches.

#### SwiftUI:

```swift
import SwiftUI
import SolanaWalletAdapterKit

@main
struct MyApp: App {
    init() {
        // Register callback scheme (without "://")
        SolanaWalletAdapter.registerCallbackScheme("yourapp")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    SolanaWalletAdapter.handleOnOpenURL(url)
                }
        }
    }
}
```

#### UIKit:

```swift
import UIKit
import SolanaWalletAdapterKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        SolanaWalletAdapter.registerCallbackScheme("yourapp")
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        SolanaWalletAdapter.handleOnOpenURL(url)
        return true
    }
}
```

## Your First Connection

Now let's connect to a wallet and retrieve the user's public key.

### Step 1: Create an App Identity

Create an `AppIdentity` that identifies your app to wallets:

```swift
import SolanaWalletAdapterKit

let appIdentity = AppIdentity(
    name: "My Solana App",
    url: URL(string: "https://myapp.com")!,
    icon: "https://myapp.com/icon.png"
)
```

### Step 2: Initialize a Wallet

Create a wallet instance for the wallet you want to connect to:

```swift
var wallet = PhantomWallet(for: appIdentity, cluster: .devnet)
```

**Available wallets:**
- `PhantomWallet` - Phantom
- `SolflareWallet` - Solflare
- `BackpackWallet` - Backpack

**Available clusters:**
- `.mainnet` - Solana mainnet-beta
- `.testnet` - Solana testnet
- `.devnet` - Solana devnet

### Step 3: Check Wallet Availability

Before connecting, check if the wallet app is installed:

```swift
guard PhantomWallet.isProbablyAvailable() else {
    print("Phantom wallet is not installed")
    // Show error or redirect to App Store
    return
}
```

### Step 4: Connect to the Wallet

```swift
do {
    try await wallet.connect()
    print("Connected! Public Key: \(wallet.publicKey!)")
} catch SolanaWalletAdapterError.userRejectedRequest {
    print("User declined the connection request")
} catch {
    print("Connection failed: \(error)")
}
```

When you call `connect()`:
1. Your app switches to the wallet app via deeplink
2. The wallet prompts the user to approve the connection
3. The wallet returns to your app with the public key
4. The connection is established with encrypted session keys

### Complete Example

```swift
import SwiftUI
import SolanaWalletAdapterKit

struct WalletConnectView: View {
    @State private var wallet: PhantomWallet?
    @State private var connectionStatus = "Not Connected"
    @State private var publicKey = ""

    let appIdentity = AppIdentity(
        name: "My Solana App",
        url: URL(string: "https://myapp.com")!,
        icon: "https://myapp.com/icon.png"
    )

    var body: some View {
        VStack(spacing: 20) {
            Text(connectionStatus)
                .font(.headline)

            if !publicKey.isEmpty {
                Text("Public Key:")
                    .font(.caption)
                Text(publicKey)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Button("Connect Phantom") {
                Task {
                    await connectWallet()
                }
            }
            .disabled(wallet?.isConnected == true)

            Button("Disconnect") {
                Task {
                    await disconnectWallet()
                }
            }
            .disabled(wallet?.isConnected == false)
        }
        .padding()
    }

    func connectWallet() async {
        guard PhantomWallet.isProbablyAvailable() else {
            connectionStatus = "Phantom not installed"
            return
        }

        var newWallet = PhantomWallet(for: appIdentity, cluster: .devnet)

        do {
            try await newWallet.connect()
            wallet = newWallet
            connectionStatus = "Connected"
            publicKey = newWallet.publicKey!.base58EncodedString
        } catch {
            connectionStatus = "Connection failed: \(error.localizedDescription)"
        }
    }

    func disconnectWallet() async {
        guard var wallet = wallet else { return }

        do {
            try await wallet.disconnect()
            self.wallet = nil
            connectionStatus = "Disconnected"
            publicKey = ""
        } catch {
            connectionStatus = "Disconnect failed: \(error.localizedDescription)"
        }
    }
}
```

## Building Transactions

Once connected, you can build and sign transactions.

### Step 1: Create an RPC Client

```swift
let rpc = SolanaRPCClient(endpoint: .devnet)
```

### Step 2: Get a Recent Blockhash

Every transaction needs a recent blockhash:

```swift
let blockhashResult = try await rpc.getLatestBlockhash()
let blockhash = blockhashResult.blockhash
```

### Step 3: Build a Transaction

Use the declarative transaction builder:

```swift
let transaction = try Transaction(
    feePayer: wallet.publicKey!,
    blockhash: blockhash
) {
    SystemProgram.transfer(
        from: wallet.publicKey!,
        to: "RecipientPublicKeyBase58String",
        lamports: 1_000_000 // 0.001 SOL
    )
}
```

### Step 4: Sign and Send

```swift
do {
    let result = try await wallet.signAndSendTransaction(
        transaction: transaction,
        sendOptions: SendOptions(
            skipPreflight: false,
            preflightCommitment: .confirmed
        )
    )
    print("Transaction successful!")
    print("Signature: \(result.signature)")
} catch SolanaWalletAdapterError.userRejectedRequest {
    print("User rejected the transaction")
} catch SolanaWalletAdapterError.transactionRejected(let message) {
    print("Transaction rejected: \(message)")
} catch {
    print("Transaction failed: \(error)")
}
```

### Complete Transaction Example

```swift
func sendSOL(to recipient: String, amount: UInt64) async throws -> String {
    guard let wallet = wallet, wallet.isConnected else {
        throw SolanaWalletAdapterError.notConnected
    }

    // Get recent blockhash
    let rpc = SolanaRPCClient(endpoint: .devnet)
    let blockhash = try await rpc.getLatestBlockhash().blockhash

    // Build transaction
    let transaction = try Transaction(
        feePayer: wallet.publicKey!,
        blockhash: blockhash
    ) {
        SystemProgram.transfer(
            from: wallet.publicKey!,
            to: recipient,
            lamports: Int64(amount)
        )
    }

    // Sign and send
    let result = try await wallet.signAndSendTransaction(
        transaction: transaction,
        sendOptions: SendOptions(
            maxRetries: 3,
            skipPreflight: false,
            preflightCommitment: .confirmed
        )
    )

    return result.signature
}
```

## Managing Persistent Sessions

Use `WalletConnectionManager` to maintain wallet connections across app launches.

### Setup

```swift
class WalletManager: ObservableObject {
    @Published var connectedWallets: [WalletType: any Wallet] = [:]

    let manager: WalletConnectionManager

    init() {
        manager = WalletConnectionManager(
            availableWallets: [
                PhantomWallet.self,
                SolflareWallet.self,
                BackpackWallet.self
            ],
            storage: KeychainStorage()
        )
    }

    func recoverSessions() async throws {
        try await manager.recoverWallets()
        connectedWallets = manager.wallets
    }

    func connectWallet(
        _ type: WalletType,
        appIdentity: AppIdentity,
        cluster: Cluster
    ) async throws {
        switch type {
        case .phantom:
            try await manager.pair(PhantomWallet.self, for: appIdentity, cluster: cluster)
        case .solflare:
            try await manager.pair(SolflareWallet.self, for: appIdentity, cluster: cluster)
        case .backpack:
            try await manager.pair(BackpackWallet.self, for: appIdentity, cluster: cluster)
        }
        connectedWallets = manager.wallets
    }

    func disconnectWallet(_ type: WalletType) async throws {
        try await manager.unpair(walletType: type)
        connectedWallets = manager.wallets
    }
}
```

### Usage

```swift
@main
struct MyApp: App {
    @StateObject private var walletManager = WalletManager()

    init() {
        SolanaWalletAdapter.registerCallbackScheme("yourapp")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(walletManager)
                .onOpenURL { url in
                    SolanaWalletAdapter.handleOnOpenURL(url)
                }
                .task {
                    try? await walletManager.recoverSessions()
                }
        }
    }
}
```

## Best Practices

### 1. Always Check Connection Status

```swift
guard wallet.isConnected else {
    // Show connection UI
    return
}
```

### 2. Handle User Rejections Gracefully

```swift
do {
    try await wallet.signTransaction(transaction: tx)
} catch SolanaWalletAdapterError.userRejectedRequest {
    // User declined - don't show error, just acknowledge
    print("User cancelled the request")
} catch {
    // Actual error - show to user
    showError(error)
}
```

### 3. Use Appropriate Commitment Levels

```swift
// For user-facing transactions
let blockhash = try await rpc.getLatestBlockhash(
    configuration: .init(commitment: .confirmed)
)

// For critical operations
let blockhash = try await rpc.getLatestBlockhash(
    configuration: .init(commitment: .finalized)
)
```

### 4. Cache Blockhashes

Blockhashes are valid for ~60 seconds. You can reuse them for multiple transactions:

```swift
struct BlockhashCache {
    let blockhash: Blockhash
    let validUntil: UInt64
    let fetchedAt: Date

    var isValid: Bool {
        Date().timeIntervalSince(fetchedAt) < 60
    }
}
```

### 5. Provide Transaction Context

Help users understand what they're signing:

```swift
// Add memos to transactions
MemoProgram.publishMemo(
    account: wallet.publicKey!,
    memo: "Payment for Order #12345"
)
```

### 6. Test on Devnet First

Always test your integration on devnet before using mainnet:

```swift
#if DEBUG
let cluster: Cluster = .devnet
#else
let cluster: Cluster = .mainnet
#endif
```

## Troubleshooting

### "User Rejected Request" Error

**Cause:** User declined the request in the wallet app.

**Solution:** This is normal behavior. Handle it gracefully without showing an error.

### Wallet App Doesn't Open

**Causes:**
1. Wallet app not installed
2. URL scheme not registered in `Info.plist`
3. Incorrect URL scheme format

**Solutions:**
- Check `isProbablyAvailable()` before connecting
- Verify `LSApplicationQueriesSchemes` in Info.plist
- Ensure URL schemes are lowercase and don't include `://`

### "Not Connected" Error

**Cause:** Attempting operations on a disconnected wallet.

**Solution:** Always check `wallet.isConnected` before operations.

### Callbacks Not Received

**Causes:**
1. URL handler not registered
2. Callback scheme mismatch
3. `handleOnOpenURL` not called

**Solutions:**
- Verify `onOpenURL` modifier (SwiftUI) or `application(_:open:)` (UIKit)
- Ensure `registerCallbackScheme` matches your URL scheme
- Check that scheme is registered in Info.plist

### Transaction Fails to Send

**Causes:**
1. Insufficient SOL for fees
2. Invalid recipient address
3. Stale blockhash

**Solutions:**
- Ensure wallet has at least 0.001 SOL for fees
- Validate addresses before building transactions
- Fetch fresh blockhash for each transaction
- Use `maxRetries` in `SendOptions`

### Connection Lost After App Restart

**Cause:** Not using `WalletConnectionManager` for persistence.

**Solution:** Implement `WalletConnectionManager` and call `recoverWallets()` on launch.

## Next Steps

Now that you've set up basic wallet integration, explore:

- [API Reference](API.md) - Complete API documentation
- [Transaction Building Guide](Transactions.md) - Advanced transaction patterns
- [Examples](Examples.md) - Complete example applications
- [Architecture](Architecture.md) - Understanding how it works

## Getting Help

- Check the [API Reference](API.md) for detailed documentation
- Review [Examples](Examples.md) for common patterns
- Open an issue on [GitHub](https://github.com/The-SolShare-Team/SolanaWalletAdapterKit/issues)
