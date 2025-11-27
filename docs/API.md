# API Reference

Complete API reference for SolanaWalletAdapterKit.

## Table of Contents

- [SolanaWalletAdapter](#solanawallet adapter)
- [Wallet Protocol](#wallet-protocol)
- [Wallet Types](#wallet-types)
- [WalletConnectionManager](#walletconnectionmanager)
- [Transaction Building](#transaction-building)
- [Programs](#programs)
- [RPC Client](#rpc-client)
- [Core Types](#core-types)
- [Error Types](#error-types)
- [Secure Storage](#secure-storage)

---

## SolanaWalletAdapter

Global singleton for handling deeplink callbacks.

### Methods

#### `registerCallbackScheme(_:)`

Registers the app's custom URL scheme for receiving wallet responses.

```swift
static func registerCallbackScheme(_ scheme: String)
```

**Parameters:**
- `scheme`: Your app's URL scheme (without `://`)

**Usage:**
```swift
SolanaWalletAdapter.registerCallbackScheme("myapp")
```

**Note:** Call once during app initialization.

---

#### `handleOnOpenURL(_:)`

Processes incoming deeplink URLs from wallet apps.

```swift
static func handleOnOpenURL(_ url: URL)
```

**Parameters:**
- `url`: The URL received from wallet app

**Usage:**
```swift
// SwiftUI
.onOpenURL { url in
    SolanaWalletAdapter.handleOnOpenURL(url)
}

// UIKit
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
    SolanaWalletAdapter.handleOnOpenURL(url)
    return true
}
```

---

## Wallet Protocol

The `Wallet` protocol defines the interface for all wallet types.

```swift
public protocol Wallet {
    associatedtype Connection: WalletConnection

    var publicKey: PublicKey? { get }
    var isConnected: Bool { get }

    mutating func connect() async throws -> Connection?
    mutating func disconnect() async throws

    func signTransaction(transaction: Transaction) async throws -> SignTransactionResponseData
    func signAllTransactions(transactions: [Transaction]) async throws -> SignAllTransactionsResponseData
    func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions?) async throws -> SignAndSendTransactionResponseData
    func signMessage(message: Data, display: SignMessageDisplay) async throws -> SignMessageResponseData
    func browse(url: URL, ref: URL?) async throws

    static func isProbablyAvailable() -> Bool
}
```

### Properties

#### `publicKey`

The connected wallet's public key, or `nil` if not connected.

```swift
var publicKey: PublicKey? { get }
```

---

#### `isConnected`

Whether the wallet is currently connected.

```swift
var isConnected: Bool { get }
```

---

### Methods

#### `connect()`

Establishes a connection with the wallet.

```swift
mutating func connect() async throws -> Connection?
```

**Returns:** Connection data containing session information

**Throws:**
- `SolanaWalletAdapterError.alreadyConnected`
- `SolanaWalletAdapterError.userRejectedRequest`

**Example:**
```swift
var wallet = PhantomWallet(for: appIdentity, cluster: .mainnet)
try await wallet.connect()
print("Connected: \(wallet.publicKey!)")
```

---

#### `disconnect()`

Terminates the wallet connection.

```swift
mutating func disconnect() async throws
```

**Throws:**
- `SolanaWalletAdapterError.notConnected`

**Example:**
```swift
try await wallet.disconnect()
```

---

#### `signTransaction(transaction:)`

Signs a single transaction.

```swift
func signTransaction(transaction: Transaction) async throws -> SignTransactionResponseData
```

**Parameters:**
- `transaction`: The transaction to sign

**Returns:** `SignTransactionResponseData` containing the signed transaction

**Throws:**
- `SolanaWalletAdapterError.notConnected`
- `SolanaWalletAdapterError.userRejectedRequest`
- `SolanaWalletAdapterError.transactionRejected`

**Example:**
```swift
let result = try await wallet.signTransaction(transaction: tx)
let signedTx = result.signedTransaction
```

---

#### `signAllTransactions(transactions:)`

Signs multiple transactions.

```swift
func signAllTransactions(transactions: [Transaction]) async throws -> SignAllTransactionsResponseData
```

**Parameters:**
- `transactions`: Array of transactions to sign

**Returns:** `SignAllTransactionsResponseData` containing signed transactions

**Example:**
```swift
let result = try await wallet.signAllTransactions(transactions: [tx1, tx2, tx3])
let signedTxs = result.signedTransactions
```

---

#### `signAndSendTransaction(transaction:sendOptions:)`

Signs a transaction and broadcasts it to the network.

```swift
func signAndSendTransaction(
    transaction: Transaction,
    sendOptions: SendOptions? = nil
) async throws -> SignAndSendTransactionResponseData
```

**Parameters:**
- `transaction`: The transaction to sign and send
- `sendOptions`: Optional send configuration

**Returns:** `SignAndSendTransactionResponseData` containing the transaction signature

**Example:**
```swift
let result = try await wallet.signAndSendTransaction(
    transaction: tx,
    sendOptions: SendOptions(
        maxRetries: 3,
        skipPreflight: false,
        preflightCommitment: .confirmed
    )
)
print("Signature: \(result.signature)")
```

---

#### `signMessage(message:display:)`

Signs an arbitrary message.

```swift
func signMessage(
    message: Data,
    display: SignMessageDisplay
) async throws -> SignMessageResponseData
```

**Parameters:**
- `message`: The message data to sign
- `display`: How to display the message (`.utf8` or `.hex`)

**Returns:** `SignMessageResponseData` containing the signature

**Example:**
```swift
let message = "Sign this message".data(using: .utf8)!
let result = try await wallet.signMessage(message: message, display: .utf8)
print("Signature: \(result.signature)")
```

---

#### `browse(url:ref:)`

Opens a URL in the wallet's in-app browser.

```swift
func browse(url: URL, ref: URL?) async throws
```

**Parameters:**
- `url`: The URL to open
- `ref`: Optional referrer URL

---

#### `isProbablyAvailable()`

Static method to check if the wallet app is installed.

```swift
static func isProbablyAvailable() -> Bool
```

**Returns:** `true` if the wallet app appears to be installed

**Example:**
```swift
if PhantomWallet.isProbablyAvailable() {
    print("Phantom is installed")
} else {
    print("Phantom not found")
}
```

---

## Wallet Types

### PhantomWallet

```swift
public struct PhantomWallet: DeeplinkWallet {
    public init(for appIdentity: AppIdentity, cluster: Cluster)
}
```

**Example:**
```swift
var wallet = PhantomWallet(for: appIdentity, cluster: .mainnet)
```

### SolflareWallet

```swift
public struct SolflareWallet: DeeplinkWallet {
    public init(for appIdentity: AppIdentity, cluster: Cluster)
}
```

**Example:**
```swift
var wallet = SolflareWallet(for: appIdentity, cluster: .devnet)
```

### BackpackWallet

```swift
public struct BackpackWallet: DeeplinkWallet {
    public init(for appIdentity: AppIdentity, cluster: Cluster)
}
```

**Example:**
```swift
var wallet = BackpackWallet(for: appIdentity, cluster: .testnet)
```

---

## WalletConnectionManager

Manages persistent wallet connections with secure storage.

### Initialization

```swift
public init(
    availableWallets: [any Wallet.Type],
    storage: SecureStorage
)
```

**Parameters:**
- `availableWallets`: Array of wallet types to support
- `storage`: Storage implementation (e.g., `KeychainStorage()`)

**Example:**
```swift
let manager = WalletConnectionManager(
    availableWallets: [
        PhantomWallet.self,
        SolflareWallet.self,
        BackpackWallet.self
    ],
    storage: KeychainStorage()
)
```

---

### Properties

#### `wallets`

Dictionary of connected wallets by type.

```swift
public var wallets: [WalletType: any Wallet] { get }
```

---

### Methods

#### `recoverWallets()`

Restores saved wallet connections from storage.

```swift
public func recoverWallets() async throws
```

**Example:**
```swift
try await manager.recoverWallets()
for (type, wallet) in manager.wallets {
    print("\(type) connected: \(wallet.publicKey!)")
}
```

---

#### `pair(_:for:cluster:)`

Connects a wallet and saves the connection.

```swift
public func pair<W: Wallet>(
    _ walletType: W.Type,
    for appIdentity: AppIdentity,
    cluster: Cluster
) async throws
```

**Parameters:**
- `walletType`: The wallet type to connect
- `appIdentity`: Your app's identity
- `cluster`: The Solana cluster

**Example:**
```swift
try await manager.pair(
    PhantomWallet.self,
    for: appIdentity,
    cluster: .mainnet
)
```

---

#### `unpair(walletType:)`

Disconnects a wallet and removes saved connection.

```swift
public func unpair(walletType: WalletType) async throws
```

**Parameters:**
- `walletType`: The wallet type to disconnect

**Example:**
```swift
try await manager.unpair(walletType: .phantom)
```

---

## Transaction Building

### Transaction

```swift
public struct Transaction {
    public init(
        feePayer: PublicKey,
        blockhash: Blockhash,
        version: TransactionVersion = .legacy,
        @InstructionsBuilder instructions: () -> [Instruction]
    ) throws
}
```

**Parameters:**
- `feePayer`: The account paying transaction fees
- `blockhash`: Recent blockhash from `getLatestBlockhash()`
- `version`: Transaction version (`.legacy` or `.v0`)
- `instructions`: Result builder for transaction instructions

**Example:**
```swift
let tx = try Transaction(
    feePayer: wallet.publicKey!,
    blockhash: blockhash
) {
    SystemProgram.transfer(
        from: wallet.publicKey!,
        to: recipient,
        lamports: 1_000_000
    )
}
```

---

### InstructionsBuilder

Result builder for declaratively constructing transaction instructions.

**Supports:**
- Multiple instructions
- `if` conditionals
- `for` loops
- `switch` statements
- Arrays of instructions

**Example:**
```swift
let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
    // Single instruction
    SystemProgram.transfer(from: sender, to: receiver, lamports: 100)

    // Conditional
    if includeMemo {
        MemoProgram.publishMemo(account: sender, memo: "Hello")
    }

    // Loop
    for recipient in recipients {
        SystemProgram.transfer(from: sender, to: recipient, lamports: 100)
    }

    // Array
    [instruction1, instruction2, instruction3]
}
```

---

## Programs

Built-in Solana program implementations.

### SystemProgram

#### `transfer(from:to:lamports:)`

Creates a SOL transfer instruction.

```swift
public static func transfer(
    from: PublicKey,
    to: PublicKey,
    lamports: Int64
) -> Instruction
```

**Parameters:**
- `from`: Source account
- `to`: Destination account
- `lamports`: Amount in lamports (1 SOL = 1,000,000,000 lamports)

**Example:**
```swift
SystemProgram.transfer(
    from: wallet.publicKey!,
    to: "RecipientAddress",
    lamports: 1_000_000 // 0.001 SOL
)
```

---

#### `createAccount(from:newAccount:lamports:space:owner:)`

Creates a new account.

```swift
public static func createAccount(
    from: PublicKey,
    newAccount: PublicKey,
    lamports: Int64,
    space: UInt64,
    owner: PublicKey
) -> Instruction
```

---

### TokenProgram

Program ID: `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`

#### `transfer(source:destination:authority:amount:)`

Transfers tokens between accounts.

```swift
public static func transfer(
    source: PublicKey,
    destination: PublicKey,
    authority: PublicKey,
    amount: UInt64
) -> Instruction
```

**Example:**
```swift
TokenProgram.transfer(
    source: sourceTokenAccount,
    destination: destTokenAccount,
    authority: wallet.publicKey!,
    amount: 100
)
```

---

#### `transferChecked(source:mint:destination:authority:amount:decimals:)`

Transfers tokens with decimal validation.

```swift
public static func transferChecked(
    source: PublicKey,
    mint: PublicKey,
    destination: PublicKey,
    authority: PublicKey,
    amount: UInt64,
    decimals: UInt8
) -> Instruction
```

---

#### `initializeMint(mint:mintAuthority:freezeAuthority:decimals:)`

Initializes a new token mint.

```swift
public static func initializeMint(
    mint: PublicKey,
    mintAuthority: PublicKey,
    freezeAuthority: PublicKey?,
    decimals: UInt8
) -> Instruction
```

---

#### `initializeAccount(account:mint:owner:)`

Initializes a token account.

```swift
public static func initializeAccount(
    account: PublicKey,
    mint: PublicKey,
    owner: PublicKey
) -> Instruction
```

---

#### `mintTo(mint:destination:authority:amount:)`

Mints new tokens to an account.

```swift
public static func mintTo(
    mint: PublicKey,
    destination: PublicKey,
    authority: PublicKey,
    amount: UInt64
) -> Instruction
```

---

#### `closeAccount(account:destination:authority:)`

Closes a token account and transfers remaining lamports.

```swift
public static func closeAccount(
    account: PublicKey,
    destination: PublicKey,
    authority: PublicKey
) -> Instruction
```

---

### AssociatedTokenProgram

Program ID: `ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL`

#### `createAssociatedTokenAccount(payer:associatedToken:owner:mint:)`

Creates an associated token account.

```swift
public static func createAssociatedTokenAccount(
    payer: PublicKey,
    associatedToken: PublicKey,
    owner: PublicKey,
    mint: PublicKey
) -> Instruction
```

**Example:**
```swift
AssociatedTokenProgram.createAssociatedTokenAccount(
    payer: wallet.publicKey!,
    associatedToken: ataAddress,
    owner: wallet.publicKey!,
    mint: tokenMint
)
```

---

### MemoProgram

Program ID: `MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr`

#### `publishMemo(account:memo:)`

Adds a memo to a transaction.

```swift
public static func publishMemo(
    account: PublicKey,
    memo: String
) -> Instruction
```

**Example:**
```swift
MemoProgram.publishMemo(
    account: wallet.publicKey!,
    memo: "Payment for order #12345"
)
```

---

## RPC Client

### SolanaRPCClient

```swift
public struct SolanaRPCClient {
    public init(endpoint: Endpoint)
}
```

**Example:**
```swift
let rpc = SolanaRPCClient(endpoint: .mainnet)
```

---

### Endpoints

```swift
public enum Endpoint {
    case mainnet
    case testnet
    case devnet
    case custom(url: URL)
}
```

---

### Methods

#### `getLatestBlockhash(configuration:)`

Retrieves the latest blockhash.

```swift
public func getLatestBlockhash(
    configuration: GetLatestBlockhashConfiguration = .init()
) async throws -> GetLatestBlockhashResult
```

**Configuration:**
```swift
public struct GetLatestBlockhashConfiguration {
    public var commitment: Commitment?
    public var minContextSlot: UInt64?
}
```

**Result:**
```swift
public struct GetLatestBlockhashResult {
    public let blockhash: Blockhash
    public let lastValidBlockHeight: UInt64
}
```

**Example:**
```swift
let result = try await rpc.getLatestBlockhash(
    configuration: .init(commitment: .confirmed)
)
let blockhash = result.blockhash
```

---

#### `sendTransaction(transaction:configuration:)`

Broadcasts a signed transaction to the network.

```swift
public func sendTransaction(
    transaction: Transaction,
    configuration: SendTransactionConfiguration = .init()
) async throws -> String
```

**Configuration:**
```swift
public struct SendTransactionConfiguration {
    public var encoding: Encoding = .base58
    public var skipPreflight: Bool = false
    public var preflightCommitment: Commitment?
    public var maxRetries: UInt64?
    public var minContextSlot: UInt64?
}
```

**Returns:** Transaction signature as a Base58 string

**Example:**
```swift
let signature = try await rpc.sendTransaction(
    transaction: signedTx,
    configuration: .init(
        skipPreflight: false,
        preflightCommitment: .processed,
        maxRetries: 3
    )
)
```

---

#### `getVersion()`

Gets the Solana node version.

```swift
public func getVersion() async throws -> GetVersionResult
```

**Result:**
```swift
public struct GetVersionResult {
    public let solanaCore: String
    public let featureSet: UInt64
}
```

**Example:**
```swift
let version = try await rpc.getVersion()
print("Solana version: \(version.solanaCore)")
```

---

## Core Types

### PublicKey

Represents a 32-byte Solana public key.

```swift
public struct PublicKey {
    public init(_ base58: String) throws
    public init(bytes: [UInt8]) throws

    public var bytes: [UInt8] { get }
    public var base58EncodedString: String { get }
}
```

**Static Methods:**
```swift
public static func findProgramAddress(
    seeds: [Data],
    programId: PublicKey
) throws -> (PublicKey, UInt8)

public static func createProgramAddress(
    seeds: [Data],
    programId: PublicKey
) throws -> PublicKey
```

**Example:**
```swift
let pubkey = try PublicKey("11111111111111111111111111111111")
let (pda, bump) = try PublicKey.findProgramAddress(
    seeds: [Data("seed".utf8)],
    programId: programId
)
```

---

### Signature

Represents a 64-byte transaction signature.

```swift
public struct Signature {
    public init(_ base58: String) throws
    public init(bytes: [UInt8]) throws

    public var bytes: [UInt8] { get }
    public var base58EncodedString: String { get }
}
```

---

### Blockhash

Represents a 32-byte blockhash.

```swift
public struct Blockhash {
    public init(_ base58: String) throws
    public init(bytes: [UInt8]) throws

    public var bytes: [UInt8] { get }
    public var base58EncodedString: String { get }
}
```

---

### AppIdentity

Identifies your app to wallets.

```swift
public struct AppIdentity {
    public let name: String
    public let url: URL
    public let icon: String

    public init(name: String, url: URL, icon: String)
}
```

---

### Cluster

Solana network cluster.

```swift
public enum Cluster: String, Codable {
    case mainnet = "mainnet-beta"
    case testnet
    case devnet
}
```

---

### Commitment

RPC commitment level.

```swift
public enum Commitment: String, Codable {
    case processed
    case confirmed
    case finalized
}
```

---

### SendOptions

Options for sending transactions.

```swift
public struct SendOptions: Codable {
    public var maxRetries: UInt64?
    public var minContextSlot: UInt64?
    public var preflightCommitment: Commitment?
    public var skipPreflight: Bool?

    public init(
        maxRetries: UInt64? = nil,
        minContextSlot: UInt64? = nil,
        preflightCommitment: Commitment? = nil,
        skipPreflight: Bool? = nil
    )
}
```

---

### SignMessageDisplay

How to display a message in the wallet.

```swift
public enum SignMessageDisplay: String, Codable {
    case utf8
    case hex
}
```

---

## Error Types

### SolanaWalletAdapterError

```swift
public enum SolanaWalletAdapterError: Error {
    case alreadyConnected
    case notConnected
    case invalidRequest(String)
    case disconnected
    case unauthorized(String)
    case userRejectedRequest(String)
    case invalidInput(String)
    case resourceNotAvailable(String)
    case transactionRejected(String)
    case methodNotFound(String)
    case internalError(String)
    case browsingFailure
}
```

**Error Descriptions:**

| Error | Description |
|-------|-------------|
| `alreadyConnected` | Wallet is already connected |
| `notConnected` | Operation requires connected wallet |
| `invalidRequest` | Malformed request data |
| `disconnected` | Wallet disconnected unexpectedly |
| `unauthorized` | Operation not authorized |
| `userRejectedRequest` | User declined in wallet app |
| `invalidInput` | Invalid parameters provided |
| `resourceNotAvailable` | Resource not found |
| `transactionRejected` | Transaction failed validation |
| `methodNotFound` | Unsupported operation |
| `internalError` | Internal error occurred |
| `browsingFailure` | Browser operation failed |

---

### RPCError

```swift
public struct RPCError: Error {
    public let code: Int
    public let message: String
    public let data: JSONValue?
}
```

**Common RPC Error Codes:**

| Code | Description |
|------|-------------|
| -32700 | Parse error |
| -32600 | Invalid request |
| -32601 | Method not found |
| -32602 | Invalid params |
| -32603 | Internal error |
| -32000 to -32099 | Server errors |

---

## Secure Storage

### SecureStorage Protocol

```swift
public protocol SecureStorage {
    func retrieve(key: String) async throws -> Data
    func retrieveAll() async throws -> [String: Data]
    func store(_ data: Data, key: String) async throws
    func clear(key: String) async throws
}
```

---

### KeychainStorage

Default implementation using iOS/macOS Keychain.

```swift
public final class KeychainStorage: SecureStorage {
    public init(
        service: String = "SolanaWalletAdapterKit",
        accessibility: Accessibility = .whenUnlockedThisDeviceOnly
    )
}
```

**Example:**
```swift
let storage = KeychainStorage(
    service: "com.myapp.wallets",
    accessibility: .whenUnlockedThisDeviceOnly
)
```

---

## Response Types

### SignTransactionResponseData

```swift
public struct SignTransactionResponseData {
    public let signedTransaction: Transaction
}
```

### SignAllTransactionsResponseData

```swift
public struct SignAllTransactionsResponseData {
    public let signedTransactions: [Transaction]
}
```

### SignAndSendTransactionResponseData

```swift
public struct SignAndSendTransactionResponseData {
    public let signature: String
}
```

### SignMessageResponseData

```swift
public struct SignMessageResponseData {
    public let signature: Signature
}
```

---

## Extension Methods

### Data

```swift
extension Data {
    public func base58EncodedString() -> String
    public init?(base58Encoded: String)
}
```

**Example:**
```swift
let data = Data([1, 2, 3, 4])
let encoded = data.base58EncodedString()
let decoded = Data(base58Encoded: encoded)
```

---

## Constants

### Program IDs

```swift
// System Program
public static let systemProgramId = "11111111111111111111111111111111"

// Token Program
public static let tokenProgramId = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"

// Associated Token Program
public static let associatedTokenProgramId = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"

// Memo Program
public static let memoProgramId = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"
```

---

## See Also

- [Getting Started Guide](GettingStarted.md)
- [Transaction Building Guide](Transactions.md)
- [Examples](Examples.md)
- [Architecture](Architecture.md)
