# Examples

Practical examples and complete implementations for common use cases with SolanaWalletAdapterKit.

## Table of Contents

- [Complete SwiftUI App](#complete-swiftui-app)
- [Wallet Connection View](#wallet-connection-view)
- [SOL Transfer View](#sol-transfer-view)
- [Token Transfer View](#token-transfer-view)
- [NFT Minting Example](#nft-minting-example)
- [Multi-Wallet Support](#multi-wallet-support)
- [Transaction History](#transaction-history)
- [Error Handling Patterns](#error-handling-patterns)
- [Testing Examples](#testing-examples)

---

## Complete SwiftUI App

A complete example SwiftUI app with wallet integration.

### App Entry Point

```swift
import SwiftUI
import SolanaWalletAdapterKit

@main
struct SolanaWalletApp: App {
    @StateObject private var walletManager = WalletManager()

    init() {
        // Register callback scheme
        SolanaWalletAdapter.registerCallbackScheme("solanawallet")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(walletManager)
                .onOpenURL { url in
                    SolanaWalletAdapter.handleOnOpenURL(url)
                }
                .task {
                    // Recover saved connections on launch
                    try? await walletManager.recoverConnections()
                }
        }
    }
}
```

### WalletManager

```swift
import Foundation
import SolanaWalletAdapterKit
import Combine

@MainActor
class WalletManager: ObservableObject {
    @Published var connectedWallet: (any Wallet)?
    @Published var walletType: WalletType?
    @Published var publicKey: PublicKey?
    @Published var isConnected = false
    @Published var errorMessage: String?

    private let connectionManager: WalletConnectionManager
    private let appIdentity: AppIdentity
    private let cluster: Cluster

    init(cluster: Cluster = .mainnet) {
        self.cluster = cluster
        self.appIdentity = AppIdentity(
            name: "My Solana App",
            url: URL(string: "https://myapp.com")!,
            icon: "https://myapp.com/icon.png"
        )

        self.connectionManager = WalletConnectionManager(
            availableWallets: [
                PhantomWallet.self,
                SolflareWallet.self,
                BackpackWallet.self
            ],
            storage: KeychainStorage()
        )
    }

    func recoverConnections() async throws {
        try await connectionManager.recoverWallets()

        // Get first connected wallet
        if let (type, wallet) = connectionManager.wallets.first {
            self.walletType = type
            self.connectedWallet = wallet
            self.publicKey = wallet.publicKey
            self.isConnected = true
        }
    }

    func connect(_ type: WalletType) async {
        do {
            // Check if wallet is available
            guard isWalletAvailable(type) else {
                errorMessage = "\(type.rawValue.capitalized) wallet is not installed"
                return
            }

            // Connect wallet
            switch type {
            case .phantom:
                try await connectionManager.pair(
                    PhantomWallet.self,
                    for: appIdentity,
                    cluster: cluster
                )
            case .solflare:
                try await connectionManager.pair(
                    SolflareWallet.self,
                    for: appIdentity,
                    cluster: cluster
                )
            case .backpack:
                try await connectionManager.pair(
                    BackpackWallet.self,
                    for: appIdentity,
                    cluster: cluster
                )
            }

            // Update state
            if let wallet = connectionManager.wallets[type] {
                self.walletType = type
                self.connectedWallet = wallet
                self.publicKey = wallet.publicKey
                self.isConnected = true
                self.errorMessage = nil
            }
        } catch SolanaWalletAdapterError.userRejectedRequest {
            errorMessage = "Connection cancelled"
        } catch {
            errorMessage = "Connection failed: \(error.localizedDescription)"
        }
    }

    func disconnect() async {
        guard let type = walletType else { return }

        do {
            try await connectionManager.unpair(walletType: type)

            // Clear state
            self.walletType = nil
            self.connectedWallet = nil
            self.publicKey = nil
            self.isConnected = false
            self.errorMessage = nil
        } catch {
            errorMessage = "Disconnect failed: \(error.localizedDescription)"
        }
    }

    private func isWalletAvailable(_ type: WalletType) -> Bool {
        switch type {
        case .phantom:
            return PhantomWallet.isProbablyAvailable()
        case .solflare:
            return SolflareWallet.isProbablyAvailable()
        case .backpack:
            return BackpackWallet.isProbablyAvailable()
        }
    }
}
```

### ContentView

```swift
import SwiftUI
import SolanaWalletAdapterKit

struct ContentView: View {
    @EnvironmentObject var walletManager: WalletManager

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if walletManager.isConnected {
                    // Connected state
                    ConnectedView()
                } else {
                    // Not connected
                    WalletSelectionView()
                }
            }
            .padding()
            .navigationTitle("Solana Wallet")
        }
    }
}
```

---

## Wallet Connection View

Complete wallet selection and connection UI.

```swift
import SwiftUI
import SolanaWalletAdapterKit

struct WalletSelectionView: View {
    @EnvironmentObject var walletManager: WalletManager
    @State private var isConnecting = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Connect Wallet")
                .font(.title)
                .fontWeight(.bold)

            if let error = walletManager.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            VStack(spacing: 12) {
                WalletButton(
                    name: "Phantom",
                    icon: "phantom-icon",
                    type: .phantom,
                    isConnecting: $isConnecting
                )

                WalletButton(
                    name: "Solflare",
                    icon: "solflare-icon",
                    type: .solflare,
                    isConnecting: $isConnecting
                )

                WalletButton(
                    name: "Backpack",
                    icon: "backpack-icon",
                    type: .backpack,
                    isConnecting: $isConnecting
                )
            }
        }
    }
}

struct WalletButton: View {
    @EnvironmentObject var walletManager: WalletManager

    let name: String
    let icon: String
    let type: WalletType
    @Binding var isConnecting: Bool

    var body: some View {
        Button(action: {
            Task {
                isConnecting = true
                await walletManager.connect(type)
                isConnecting = false
            }
        }) {
            HStack {
                Image(systemName: "wallet.pass")
                    .font(.title2)

                Text(name)
                    .font(.headline)

                Spacer()

                if isConnecting {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isConnecting)
    }
}
```

### Connected State View

```swift
import SwiftUI
import SolanaWalletAdapterKit

struct ConnectedView: View {
    @EnvironmentObject var walletManager: WalletManager

    var body: some View {
        VStack(spacing: 24) {
            // Wallet Info
            VStack(spacing: 8) {
                Text("Connected")
                    .font(.headline)
                    .foregroundColor(.green)

                if let publicKey = walletManager.publicKey {
                    Text(publicKey.base58EncodedString)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .padding(.horizontal)
                }

                if let type = walletManager.walletType {
                    Text(type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)

            // Actions
            VStack(spacing: 12) {
                NavigationLink(destination: TransferSOLView()) {
                    ActionButton(title: "Send SOL", icon: "paperplane")
                }

                NavigationLink(destination: TransferTokenView()) {
                    ActionButton(title: "Send Tokens", icon: "doc.on.doc")
                }

                NavigationLink(destination: SignMessageView()) {
                    ActionButton(title: "Sign Message", icon: "signature")
                }
            }

            Spacer()

            // Disconnect Button
            Button(action: {
                Task {
                    await walletManager.disconnect()
                }
            }) {
                Text("Disconnect")
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}
```

---

## SOL Transfer View

Complete SOL transfer implementation with validation.

```swift
import SwiftUI
import SolanaWalletAdapterKit

struct TransferSOLView: View {
    @EnvironmentObject var walletManager: WalletManager
    @Environment(\.dismiss) var dismiss

    @State private var recipientAddress = ""
    @State private var amount = ""
    @State private var memo = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var successSignature: String?

    var body: some View {
        Form {
            Section("Transfer Details") {
                TextField("Recipient Address", text: $recipientAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))

                TextField("Amount (SOL)", text: $amount)
                    .keyboardType(.decimalPad)

                TextField("Memo (Optional)", text: $memo)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            if let signature = successSignature {
                Section("Success") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transaction sent!")
                            .foregroundColor(.green)
                            .fontWeight(.bold)

                        Text("Signature:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(signature)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(2)
                    }
                }
            }

            Section {
                Button(action: sendSOL) {
                    if isProcessing {
                        HStack {
                            ProgressView()
                            Text("Processing...")
                        }
                    } else {
                        Text("Send SOL")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isProcessing || !isValid)
            }
        }
        .navigationTitle("Send SOL")
    }

    private var isValid: Bool {
        !recipientAddress.isEmpty &&
        !amount.isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0
    }

    private func sendSOL() {
        Task {
            isProcessing = true
            errorMessage = nil
            successSignature = nil

            do {
                guard let wallet = walletManager.connectedWallet else {
                    throw SolanaWalletAdapterError.notConnected
                }

                // Validate amount
                guard let amountDouble = Double(amount) else {
                    throw ValidationError.invalidAmount
                }
                let lamports = UInt64(amountDouble * 1_000_000_000)

                // Validate recipient
                let recipient = try PublicKey(recipientAddress)

                // Create RPC client
                let rpc = SolanaRPCClient(endpoint: .mainnet)

                // Get blockhash
                let blockhash = try await rpc.getLatestBlockhash().blockhash

                // Build transaction
                let transaction = try Transaction(
                    feePayer: wallet.publicKey!,
                    blockhash: blockhash
                ) {
                    SystemProgram.transfer(
                        from: wallet.publicKey!,
                        to: recipient,
                        lamports: Int64(lamports)
                    )

                    if !memo.isEmpty {
                        MemoProgram.publishMemo(
                            account: wallet.publicKey!,
                            memo: memo
                        )
                    }
                }

                // Sign and send
                let result = try await (wallet as! PhantomWallet).signAndSendTransaction(
                    transaction: transaction,
                    sendOptions: SendOptions(
                        maxRetries: 3,
                        skipPreflight: false,
                        preflightCommitment: .confirmed
                    )
                )

                successSignature = result.signature

                // Clear form
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } catch SolanaWalletAdapterError.userRejectedRequest {
                errorMessage = "Transaction cancelled"
            } catch SolanaWalletAdapterError.transactionRejected(let message) {
                errorMessage = "Transaction rejected: \(message)"
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }

            isProcessing = false
        }
    }
}

enum ValidationError: Error {
    case invalidAmount
    case invalidAddress
}
```

---

## Token Transfer View

SPL token transfer with ATA creation.

```swift
import SwiftUI
import SolanaWalletAdapterKit

struct TransferTokenView: View {
    @EnvironmentObject var walletManager: WalletManager
    @Environment(\.dismiss) var dismiss

    @State private var tokenMint = ""
    @State private var recipientAddress = ""
    @State private var amount = ""
    @State private var decimals = "6"
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var successSignature: String?

    var body: some View {
        Form {
            Section("Token Details") {
                TextField("Token Mint Address", text: $tokenMint)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))

                TextField("Decimals", text: $decimals)
                    .keyboardType(.numberPad)
            }

            Section("Transfer Details") {
                TextField("Recipient Address", text: $recipientAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))

                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            if let signature = successSignature {
                Section("Success") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tokens sent!")
                            .foregroundColor(.green)
                            .fontWeight(.bold)

                        Text(signature)
                            .font(.system(.caption, design: .monospaced))
                            .lineLimit(2)
                    }
                }
            }

            Section {
                Button(action: sendTokens) {
                    if isProcessing {
                        HStack {
                            ProgressView()
                            Text("Processing...")
                        }
                    } else {
                        Text("Send Tokens")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isProcessing || !isValid)
            }
        }
        .navigationTitle("Send Tokens")
    }

    private var isValid: Bool {
        !tokenMint.isEmpty &&
        !recipientAddress.isEmpty &&
        !amount.isEmpty &&
        Double(amount) != nil &&
        UInt8(decimals) != nil
    }

    private func sendTokens() {
        Task {
            isProcessing = true
            errorMessage = nil
            successSignature = nil

            do {
                guard let wallet = walletManager.connectedWallet else {
                    throw SolanaWalletAdapterError.notConnected
                }

                // Parse inputs
                guard let amountDouble = Double(amount),
                      let decimalsUInt8 = UInt8(decimals) else {
                    throw ValidationError.invalidAmount
                }

                let mint = try PublicKey(tokenMint)
                let recipient = try PublicKey(recipientAddress)

                // Calculate amount in smallest unit
                let lamports = UInt64(amountDouble * pow(10.0, Double(decimalsUInt8)))

                // Calculate ATAs
                let fromATA = try PublicKey.findProgramAddress(
                    seeds: [
                        wallet.publicKey!.bytes,
                        try PublicKey("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA").bytes,
                        mint.bytes
                    ],
                    programId: try PublicKey("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
                ).0

                let toATA = try PublicKey.findProgramAddress(
                    seeds: [
                        recipient.bytes,
                        try PublicKey("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA").bytes,
                        mint.bytes
                    ],
                    programId: try PublicKey("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
                ).0

                // Get blockhash
                let rpc = SolanaRPCClient(endpoint: .mainnet)
                let blockhash = try await rpc.getLatestBlockhash().blockhash

                // Build transaction
                let transaction = try Transaction(
                    feePayer: wallet.publicKey!,
                    blockhash: blockhash
                ) {
                    // Create recipient ATA
                    AssociatedTokenProgram.createAssociatedTokenAccount(
                        payer: wallet.publicKey!,
                        associatedToken: toATA,
                        owner: recipient,
                        mint: mint
                    )

                    // Transfer tokens
                    TokenProgram.transferChecked(
                        source: fromATA,
                        mint: mint,
                        destination: toATA,
                        authority: wallet.publicKey!,
                        amount: lamports,
                        decimals: decimalsUInt8
                    )
                }

                // Sign and send
                let result = try await (wallet as! PhantomWallet).signAndSendTransaction(
                    transaction: transaction,
                    sendOptions: SendOptions(maxRetries: 3)
                )

                successSignature = result.signature

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }

            isProcessing = false
        }
    }
}
```

---

## Sign Message View

Message signing implementation.

```swift
import SwiftUI
import SolanaWalletAdapterKit

struct SignMessageView: View {
    @EnvironmentObject var walletManager: WalletManager

    @State private var message = ""
    @State private var displayFormat: SignMessageDisplay = .utf8
    @State private var signature: String?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Message") {
                TextEditor(text: $message)
                    .frame(height: 120)
                    .font(.system(.body, design: .monospaced))

                Picker("Display Format", selection: $displayFormat) {
                    Text("UTF-8").tag(SignMessageDisplay.utf8)
                    Text("Hex").tag(SignMessageDisplay.hex)
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }

            if let sig = signature {
                Section("Signature") {
                    Text(sig)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(3)
                }
            }

            Section {
                Button(action: signMessage) {
                    if isProcessing {
                        HStack {
                            ProgressView()
                            Text("Signing...")
                        }
                    } else {
                        Text("Sign Message")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(message.isEmpty || isProcessing)
            }
        }
        .navigationTitle("Sign Message")
    }

    private func signMessage() {
        Task {
            isProcessing = true
            errorMessage = nil
            signature = nil

            do {
                guard let wallet = walletManager.connectedWallet else {
                    throw SolanaWalletAdapterError.notConnected
                }

                guard let messageData = message.data(using: .utf8) else {
                    throw ValidationError.invalidMessage
                }

                let result = try await (wallet as! PhantomWallet).signMessage(
                    message: messageData,
                    display: displayFormat
                )

                signature = result.signature.base58EncodedString
            } catch SolanaWalletAdapterError.userRejectedRequest {
                errorMessage = "Signing cancelled"
            } catch {
                errorMessage = "Error: \(error.localizedDescription)"
            }

            isProcessing = false
        }
    }
}

extension ValidationError {
    static let invalidMessage = ValidationError.invalidAmount
}
```

---

## Multi-Wallet Support

Managing multiple wallet connections.

```swift
import SwiftUI
import SolanaWalletAdapterKit

struct MultiWalletView: View {
    @StateObject private var manager = MultiWalletManager()

    var body: some View {
        List {
            Section("Connected Wallets") {
                ForEach(manager.connectedWallets, id: \.type) { info in
                    WalletRow(info: info, manager: manager)
                }
            }

            Section("Available Wallets") {
                ForEach(manager.availableWalletTypes, id: \.self) { type in
                    if !manager.isConnected(type) {
                        Button("Connect \(type.rawValue.capitalized)") {
                            Task {
                                await manager.connect(type)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Multi-Wallet")
        .task {
            await manager.recoverAll()
        }
    }
}

struct WalletRow: View {
    let info: WalletInfo
    let manager: MultiWalletManager

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(info.type.rawValue.capitalized)
                    .font(.headline)

                Text(info.publicKey.base58EncodedString)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("Disconnect") {
                Task {
                    await manager.disconnect(info.type)
                }
            }
            .foregroundColor(.red)
        }
    }
}

struct WalletInfo {
    let type: WalletType
    let publicKey: PublicKey
}

@MainActor
class MultiWalletManager: ObservableObject {
    @Published var connectedWallets: [WalletInfo] = []

    private let connectionManager: WalletConnectionManager
    private let appIdentity: AppIdentity

    let availableWalletTypes: [WalletType] = [.phantom, .solflare, .backpack]

    init() {
        self.appIdentity = AppIdentity(
            name: "Multi-Wallet App",
            url: URL(string: "https://myapp.com")!,
            icon: "https://myapp.com/icon.png"
        )

        self.connectionManager = WalletConnectionManager(
            availableWallets: [
                PhantomWallet.self,
                SolflareWallet.self,
                BackpackWallet.self
            ],
            storage: KeychainStorage()
        )
    }

    func recoverAll() async {
        do {
            try await connectionManager.recoverWallets()
            updateConnectedWallets()
        } catch {
            print("Recovery error: \(error)")
        }
    }

    func connect(_ type: WalletType) async {
        do {
            switch type {
            case .phantom:
                try await connectionManager.pair(
                    PhantomWallet.self,
                    for: appIdentity,
                    cluster: .mainnet
                )
            case .solflare:
                try await connectionManager.pair(
                    SolflareWallet.self,
                    for: appIdentity,
                    cluster: .mainnet
                )
            case .backpack:
                try await connectionManager.pair(
                    BackpackWallet.self,
                    for: appIdentity,
                    cluster: .mainnet
                )
            }
            updateConnectedWallets()
        } catch {
            print("Connection error: \(error)")
        }
    }

    func disconnect(_ type: WalletType) async {
        do {
            try await connectionManager.unpair(walletType: type)
            updateConnectedWallets()
        } catch {
            print("Disconnect error: \(error)")
        }
    }

    func isConnected(_ type: WalletType) -> Bool {
        connectedWallets.contains { $0.type == type }
    }

    private func updateConnectedWallets() {
        connectedWallets = connectionManager.wallets.compactMap { type, wallet in
            guard let publicKey = wallet.publicKey else { return nil }
            return WalletInfo(type: type, publicKey: publicKey)
        }
    }
}
```

---

## Error Handling Patterns

Best practices for handling errors.

```swift
import SolanaWalletAdapterKit

// Comprehensive error handling
func handleTransaction() async {
    do {
        let result = try await wallet.signAndSendTransaction(transaction: tx)
        await showSuccess(result.signature)
    } catch SolanaWalletAdapterError.userRejectedRequest(let message) {
        // User cancelled - don't show as error
        print("User cancelled: \(message)")
    } catch SolanaWalletAdapterError.transactionRejected(let message) {
        // Transaction failed validation
        await showError("Transaction failed: \(message)")
    } catch SolanaWalletAdapterError.notConnected {
        // Wallet not connected
        await showError("Please connect your wallet first")
    } catch SolanaWalletAdapterError.invalidInput(let message) {
        // Invalid parameters
        await showError("Invalid input: \(message)")
    } catch {
        // Unexpected errors
        await showError("Unexpected error: \(error.localizedDescription)")
    }
}

// Retry logic
func sendWithRetry(maxAttempts: Int = 3) async throws -> String {
    var lastError: Error?

    for attempt in 1...maxAttempts {
        do {
            let result = try await wallet.signAndSendTransaction(transaction: tx)
            return result.signature
        } catch SolanaWalletAdapterError.userRejectedRequest {
            // Don't retry user cancellations
            throw SolanaWalletAdapterError.userRejectedRequest("Cancelled")
        } catch {
            lastError = error
            if attempt < maxAttempts {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            }
        }
    }

    throw lastError ?? SolanaWalletAdapterError.internalError("Retry failed")
}
```

---

## Testing Examples

Unit testing wallet integration.

```swift
import XCTest
@testable import YourApp
import SolanaWalletAdapterKit

// Mock storage for testing
class MockStorage: SecureStorage {
    var storage: [String: Data] = [:]

    func retrieve(key: String) async throws -> Data {
        guard let data = storage[key] else {
            throw NSError(domain: "MockStorage", code: 404)
        }
        return data
    }

    func retrieveAll() async throws -> [String: Data] {
        return storage
    }

    func store(_ data: Data, key: String) async throws {
        storage[key] = data
    }

    func clear(key: String) async throws {
        storage.removeValue(forKey: key)
    }
}

// Test wallet manager
class WalletManagerTests: XCTestCase {
    var mockStorage: MockStorage!
    var manager: WalletConnectionManager!

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
        manager = WalletConnectionManager(
            availableWallets: [PhantomWallet.self],
            storage: mockStorage
        )
    }

    func testStoragePersistence() async throws {
        // Test that connections are persisted
        XCTAssertTrue(mockStorage.storage.isEmpty)

        // Connect wallet (would require actual wallet interaction in real test)
        // ...

        // Verify storage
        let all = try await mockStorage.retrieveAll()
        XCTAssertFalse(all.isEmpty)
    }
}

// Test transaction building
class TransactionBuilderTests: XCTestCase {
    func testSimpleTransfer() throws {
        let feePayer = try PublicKey("11111111111111111111111111111111")
        let recipient = try PublicKey("22222222222222222222222222222222")
        let blockhash = try Blockhash("11111111111111111111111111111111")

        let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
            SystemProgram.transfer(
                from: feePayer,
                to: recipient,
                lamports: 1_000_000
            )
        }

        // Verify transaction structure
        XCTAssertNotNil(tx)
        // Additional assertions...
    }
}
```

---

## See Also

- [Getting Started Guide](GettingStarted.md)
- [API Reference](API.md)
- [Transaction Building Guide](Transactions.md)
- [Architecture](Architecture.md)
