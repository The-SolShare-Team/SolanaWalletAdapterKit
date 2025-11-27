# Architecture Overview

This document explains the architecture and design principles of SolanaWalletAdapterKit.

## Table of Contents

- [High-Level Architecture](#high-level-architecture)
- [Module Structure](#module-structure)
- [Deeplink Communication Flow](#deeplink-communication-flow)
- [Encryption and Security](#encryption-and-security)
- [Transaction Lifecycle](#transaction-lifecycle)
- [Connection Persistence](#connection-persistence)
- [Design Principles](#design-principles)
- [Threading Model](#threading-model)

---

## High-Level Architecture

SolanaWalletAdapterKit is designed as a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                   Application Layer                      │
│  (Your iOS/macOS App using WalletConnectionManager)     │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│              SolanaWalletAdapterKit Module               │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Wallet Protocol & Implementations               │  │
│  │  - PhantomWallet, SolflareWallet, BackpackWallet │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Connection Management                           │  │
│  │  - WalletConnectionManager                       │  │
│  │  - SavedWalletConnection                         │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Deeplink Communication                          │  │
│  │  - DeeplinkWallet protocol                       │  │
│  │  - DeeplinkFetcher                               │  │
│  │  - SolanaWalletAdapter (global handler)          │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Secure Storage                                  │  │
│  │  - SecureStorage protocol                        │  │
│  │  - KeychainStorage                               │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
┌────────────────┐ ┌─────────────┐ ┌──────────────┐
│ SolanaRPC      │ │ Solana      │ │ Salt         │
│ Module         │ │ Transactions│ │ Module       │
│                │ │ Module      │ │              │
│ - RPC Client   │ │ - Builder   │ │ - Crypto     │
│ - Methods      │ │ - Programs  │ │ - DH Keys    │
│ - Types        │ │ - Types     │ │ - Nonces     │
└────────────────┘ └─────────────┘ └──────────────┘
         │                │                │
         └────────────────┼────────────────┘
                          ▼
                  ┌──────────────┐
                  │ Base58       │
                  │ Module       │
                  │              │
                  │ - Encoding   │
                  │ - Decoding   │
                  └──────────────┘
```

---

## Module Structure

### 1. Base58 Module

**Purpose:** Foundation layer for encoding/decoding Solana data.

**Components:**
- `Data` extensions for Base58 encoding/decoding
- Used by all modules for public keys, signatures, blockhashes

**Dependencies:** None (foundation layer)

**Design Notes:**
- Immutable, pure functions
- No side effects
- Thread-safe by design

---

### 2. Salt Module

**Purpose:** Cryptographic primitives wrapper.

**Components:**
- `SaltBox`: NaCl box encryption/decryption
- `SaltSign`: Ed25519 signing
- `SaltSecretBox`: Secret box encryption
- `SaltScalarMult`: Diffie-Hellman key exchange
- `generateNonce()`: Secure random nonce generation
- `isOnCurve()`: Ed25519 curve validation

**Dependencies:**
- TweetNacl (external)
- Salkt.swift (external)

**Design Notes:**
- Thin wrapper over C-based crypto libraries
- Type-safe Swift API
- No state - pure functional interface

---

### 3. SolanaTransactions Module

**Purpose:** Transaction building, serialization, and program interfaces.

**Key Components:**

#### Transaction Builder
```swift
Transaction(feePayer:blockhash:) {
    // Declarative instructions
}
```

**Features:**
- Result builder DSL (`@InstructionsBuilder`)
- Automatic account deduplication
- Account ordering (writable signers, readonly signers, writable non-signers, readonly non-signers)
- Support for Legacy and V0 transactions
- Address lookup table support

#### Built-in Programs
- `SystemProgram`: SOL transfers, account creation
- `TokenProgram`: SPL token operations
- `AssociatedTokenProgram`: ATA management
- `MemoProgram`: Transaction memos

#### Core Types
- `PublicKey`: 32-byte account identifier
- `Signature`: 64-byte Ed25519 signature
- `Blockhash`: 32-byte recent blockhash
- `Instruction`: Program instruction with accounts and data

**Dependencies:**
- Base58
- SwiftBorsh (serialization)
- Salt (cryptography)
- Swift Collections (ordered sets)

**Design Notes:**
- Value types (structs) for immutability
- Declarative API using result builders
- Type-safe instruction building
- Supports both Legacy and Versioned message formats

---

### 4. SolanaRPC Module

**Purpose:** Type-safe JSON-RPC client for Solana blockchain.

**Key Components:**

#### RPC Client
```swift
SolanaRPCClient(endpoint: .mainnet)
```

**Available Methods:**
- `getLatestBlockhash()`: Get recent blockhash
- `sendTransaction()`: Broadcast transactions
- `getVersion()`: Get node version

**Error Handling:**
- `RPCError` with standard JSON-RPC error codes
- Typed error responses with `data` field

**Dependencies:**
- SolanaTransactions
- SwiftBorsh
- Foundation (URLSession)

**Design Notes:**
- Async/await based API
- Generic `fetch()` method for extensibility
- Type-safe request/response structures
- Automatic JSON-RPC 2.0 envelope handling

---

### 5. SolanaWalletAdapterKit Module

**Purpose:** Wallet connection, management, and deeplink communication.

#### 5.1 Global Deeplink Handler

**`SolanaWalletAdapter`** - Singleton for routing deeplink responses.

```swift
// Registers callback URL scheme
SolanaWalletAdapter.registerCallbackScheme("myapp")

// Routes incoming URLs to waiting requests
SolanaWalletAdapter.handleOnOpenURL(url)
```

**Design:**
- Global mutable state (necessary for deeplink handling)
- Thread-safe concurrent access
- Routes URLs to `DeeplinkFetcher` instances

#### 5.2 Wallet Protocol Hierarchy

```
           Wallet (protocol)
               │
               ├─── DeeplinkWallet (protocol)
               │        │
               │        ├─── PhantomWallet
               │        ├─── SolflareWallet
               │        └─── BackpackWallet
               │
               └─── (Future: WebWallet, etc.)
```

**Wallet Protocol:**
- Defines unified interface for all wallets
- Operations: connect, disconnect, sign, send, browse
- Generic over `Connection` type

**DeeplinkWallet Protocol:**
- Extends `Wallet` for deeplink-based wallets
- Handles encryption, session management
- Default implementations for all operations

#### 5.3 Deeplink Communication

**`DeeplinkFetcher`** - Manages async deeplink requests/responses.

**Flow:**
1. Generate unique callback URL
2. Register callback handler
3. Open wallet via deeplink
4. Wait for response (with timeout)
5. Parse and return response
6. Cleanup callback handler

**Design:**
- One fetcher per request
- Timeout handling (default 30s)
- Automatic cleanup
- Type-safe response parsing

#### 5.4 Connection Management

**`WalletConnectionManager`** - Persistent connection lifecycle.

**Responsibilities:**
- Connect/disconnect wallets
- Persist connections to secure storage
- Recover connections on app launch
- Manage multiple concurrent wallet connections

**Storage Format:**
```swift
SavedWalletConnection {
    walletType: WalletType
    connectionData: Data  // Encoded DeeplinkWalletConnection
    appIdentity: AppIdentity
    cluster: Cluster
}
```

**Storage Key:**
- SHA256 hash of (walletType + appIdentity + cluster + publicKey)
- Ensures unique storage per wallet/app/cluster combination

#### 5.5 Secure Storage

**`SecureStorage` Protocol:**
- Abstract interface for secure key-value storage
- Async API for all operations

**`KeychainStorage` Implementation:**
- Uses iOS/macOS Keychain via SimpleKeychain
- Default accessibility: `.whenUnlockedThisDeviceOnly`
- Namespace: "SolanaWalletAdapterKit"

**Dependencies:**
- All other modules
- SimpleKeychain
- Foundation

**Design Notes:**
- Protocol-oriented design for testability
- Mutation via `inout self` for value types
- Encrypted communication via Diffie-Hellman
- Persistent session management

---

## Deeplink Communication Flow

### Connection Flow

```
┌─────────┐                    ┌──────────────┐                ┌────────────┐
│   App   │                    │ Wallet App   │                │  Network   │
└────┬────┘                    └──────┬───────┘                └─────┬──────┘
     │                                │                              │
     │ 1. connect()                   │                              │
     ├──────────────────┐             │                              │
     │                  │             │                              │
     │ 2. Generate DH   │             │                              │
     │    keypair       │             │                              │
     │◄─────────────────┘             │                              │
     │                                │                              │
     │ 3. Open deeplink               │                              │
     │ phantom://v1/connect?          │                              │
     │   dapp_encryption_public_key=X │                              │
     │   cluster=mainnet              │                              │
     │   app_url=myapp://callback     │                              │
     │   redirect_link=myapp://       │                              │
     ├───────────────────────────────>│                              │
     │                                │                              │
     │                                │ 4. User approves             │
     │                                │    connection                │
     │                                │                              │
     │ 5. Callback deeplink           │                              │
     │ myapp://callback?              │                              │
     │   phantom_encryption_public_key│                              │
     │   nonce=...                    │                              │
     │   data=<encrypted:             │                              │
     │     {public_key, session}>     │                              │
     │◄───────────────────────────────┤                              │
     │                                │                              │
     │ 6. Compute shared              │                              │
     │    secret from DH              │                              │
     ├──────────────────┐             │                              │
     │                  │             │                              │
     │ 7. Decrypt data  │             │                              │
     │◄─────────────────┘             │                              │
     │                                │                              │
     │ 8. Store session               │                              │
     │    and public key              │                              │
     ├──────────────────┐             │                              │
     │                  │             │                              │
     │◄─────────────────┘             │                              │
     │                                │                              │
```

### Transaction Signing Flow

```
┌─────────┐                    ┌──────────────┐                ┌────────────┐
│   App   │                    │ Wallet App   │                │  Network   │
└────┬────┘                    └──────┬───────┘                └─────┬──────┘
     │                                │                              │
     │ 1. signTransaction()           │                              │
     ├──────────────────┐             │                              │
     │                  │             │                              │
     │ 2. Serialize tx  │             │                              │
     │◄─────────────────┘             │                              │
     │                                │                              │
     │ 3. Generate nonce              │                              │
     ├──────────────────┐             │                              │
     │                  │             │                              │
     │ 4. Encrypt tx    │             │                              │
     │    with shared   │             │                              │
     │    secret        │             │                              │
     │◄─────────────────┘             │                              │
     │                                │                              │
     │ 5. Open deeplink               │                              │
     │ phantom://v1/signTransaction?  │                              │
     │   session=...                  │                              │
     │   nonce=...                    │                              │
     │   payload=<encrypted:          │                              │
     │     {transaction}>             │                              │
     ├───────────────────────────────>│                              │
     │                                │                              │
     │                                │ 6. Decrypt with              │
     │                                │    shared secret             │
     │                                │                              │
     │                                │ 7. Display tx                │
     │                                │    to user                   │
     │                                │                              │
     │                                │ 8. User approves             │
     │                                │    and signs                 │
     │                                │                              │
     │ 9. Callback deeplink           │                              │
     │ myapp://callback?              │                              │
     │   nonce=...                    │                              │
     │   data=<encrypted:             │                              │
     │     {signed_transaction}>      │                              │
     │◄───────────────────────────────┤                              │
     │                                │                              │
     │ 10. Decrypt response           │                              │
     ├──────────────────┐             │                              │
     │                  │             │                              │
     │ 11. Return       │             │                              │
     │     signed tx    │             │                              │
     │◄─────────────────┘             │                              │
     │                                │                              │
```

---

## Encryption and Security

### Diffie-Hellman Key Exchange

SolanaWalletAdapterKit uses Curve25519 Diffie-Hellman for encrypted communication.

**Connection Phase:**
1. App generates ephemeral DH keypair (32-byte private, 32-byte public)
2. App sends public key to wallet in connect deeplink
3. Wallet generates its own DH keypair
4. Wallet sends its public key back to app
5. Both parties compute shared secret: `scalar_mult(privateKey, otherPublicKey)`
6. Shared secret used for all subsequent encrypted communication

**Encryption:**
- Algorithm: NaCl box (authenticated encryption)
- Each message has unique 24-byte nonce
- Ciphertext includes authentication tag
- Prevents tampering and replay attacks

**Security Properties:**
- Forward secrecy (ephemeral keys)
- Authentication (via NaCl box)
- Confidentiality (symmetric encryption)
- Integrity (authenticated encryption)

### Session Management

**Session Identifier:**
- Random UUID generated during connection
- Sent with every request to associate with connection
- Wallet validates session before processing requests

**Session Storage:**
- Encrypted connection data in Keychain
- Includes: session ID, DH keys, shared secret, public key
- Accessibility: `.whenUnlockedThisDeviceOnly`
- Automatic cleanup on disconnect

**Session Recovery:**
- Connections restored from Keychain on app launch
- Shared secret recomputed from stored DH keys
- Sessions remain valid until explicit disconnect

---

## Transaction Lifecycle

### Building

```swift
Transaction(feePayer: pk, blockhash: hash) {
    // Instructions collected via result builder
}
```

1. **Instruction Collection:** Result builder gathers all instructions
2. **Account Extraction:** Extract accounts from each instruction
3. **Account Deduplication:** Remove duplicate accounts, merge flags
4. **Account Ordering:**
   - Fee payer (writable + signer)
   - Other writable signers
   - Readonly signers
   - Writable non-signers
   - Readonly non-signers
5. **Instruction Compilation:** Replace account public keys with indices
6. **Message Construction:** Build Legacy or V0 message
7. **Placeholder Signatures:** Add empty signatures (filled during signing)

### Serialization

**Legacy Transaction Format:**
```
[
    num_signatures: compact_u16,
    [signature: [u8; 64]] * num_signatures,
    message: [
        num_required_signatures: u8,
        num_readonly_signed_accounts: u8,
        num_readonly_unsigned_accounts: u8,
        num_accounts: compact_u16,
        [account: [u8; 32]] * num_accounts,
        blockhash: [u8; 32],
        num_instructions: compact_u16,
        [instruction] * num_instructions
    ]
]
```

**Instruction Format:**
```
[
    program_id_index: u8,
    num_accounts: compact_u16,
    [account_index: u8] * num_accounts,
    data_length: compact_u16,
    [data: u8] * data_length
]
```

### Signing

1. **Wallet Receives:** Base58-encoded transaction
2. **Wallet Decodes:** Parse transaction structure
3. **Wallet Signs:** Generate Ed25519 signature over message bytes
4. **Wallet Encodes:** Base58-encode signed transaction
5. **App Receives:** Signed transaction with all signatures filled

### Sending

1. **RPC Serialization:** Transaction serialized to Base58 or Base64
2. **HTTP Request:** JSON-RPC 2.0 request to Solana node
3. **Preflight Checks:** Optional simulation before broadcast
4. **Broadcast:** Transaction sent to leader
5. **Confirmation:** Monitor transaction status via commitment levels

---

## Connection Persistence

### Storage Architecture

```
┌──────────────────────────────────────────┐
│         WalletConnectionManager          │
│                                          │
│  wallets: [WalletType: any Wallet]      │
│  storage: SecureStorage                  │
└──────────────────┬───────────────────────┘
                   │
                   │ save/load
                   ▼
┌──────────────────────────────────────────┐
│          SecureStorage Protocol          │
└──────────────────┬───────────────────────┘
                   │
                   │ implements
                   ▼
┌──────────────────────────────────────────┐
│           KeychainStorage                │
│                                          │
│  Uses: iOS/macOS Keychain                │
│  Service: "SolanaWalletAdapterKit"       │
│  Accessibility: whenUnlockedThisDeviceOnly│
└──────────────────────────────────────────┘
```

### Saved Connection Format

```swift
SavedWalletConnection {
    walletType: "phantom" | "solflare" | "backpack"
    connectionData: Data  // Encoded DeeplinkWalletConnection
    appIdentity: {
        name: String,
        url: URL,
        icon: String
    }
    cluster: "mainnet-beta" | "testnet" | "devnet"
}
```

**Connection Data (Encrypted):**
```swift
DeeplinkWalletConnection {
    session: UUID
    encryption: {
        publicKey: [UInt8; 32]
        privateKey: [UInt8; 32]
        sharedSecret: [UInt8; 32]
    }
    publicKey: [UInt8; 32]  // Wallet's public key
}
```

### Recovery Flow

```
App Launch
    │
    ├─> WalletConnectionManager.recoverWallets()
    │       │
    │       ├─> storage.retrieveAll()
    │       │       │
    │       │       └─> Read all saved connections from Keychain
    │       │
    │       ├─> Decode each SavedWalletConnection
    │       │
    │       ├─> For each connection:
    │       │       ├─> Identify wallet type
    │       │       ├─> Decode connection data
    │       │       ├─> Create wallet instance
    │       │       └─> Restore session and encryption
    │       │
    │       └─> Populate wallets dictionary
    │
    └─> App ready with restored connections
```

---

## Design Principles

### 1. Protocol-Oriented Design

- `Wallet` protocol for wallet abstraction
- `SecureStorage` protocol for storage abstraction
- `DeeplinkWallet` protocol for deeplink wallets
- Easy to add new wallet types or storage backends

### 2. Value Semantics

- Structs for most types (PublicKey, Transaction, etc.)
- Immutability by default
- Explicit mutation with `inout self`
- Thread-safe value types

### 3. Type Safety

- Strong typing for public keys, signatures, blockhashes
- No raw strings or byte arrays in public API
- Compile-time guarantees for instruction parameters
- Generic programming for extensibility

### 4. Swift Concurrency

- Async/await for all asynchronous operations
- No completion handlers or callbacks
- Structured concurrency with task groups
- Actor-based synchronization where needed

### 5. Error Handling

- Typed errors (not NSError)
- Specific error cases for each domain
- Error messages include context
- No silent failures

### 6. Declarative APIs

- Result builders for transaction construction
- SwiftUI-style declarative syntax
- Readable, self-documenting code
- Composable instruction building

### 7. Minimal External Dependencies

- Only essential external packages
- Prefer Swift standard library
- Thin wrappers over C libraries
- No unnecessary abstractions

---

## Threading Model

### Concurrency Architecture

**Thread-Safe Components:**
- All value types (PublicKey, Transaction, etc.)
- `SolanaWalletAdapter` (uses locks for shared state)
- `DeeplinkFetcher` (actor-isolated continuations)

**Main Thread Requirements:**
- Deeplink URL opening (requires main thread on iOS)
- None of the public APIs require main thread

**Async Operations:**
- All network requests (RPC client)
- All wallet operations (connect, sign, send)
- Storage operations (Keychain access)

**Isolation:**
```swift
// SolanaWalletAdapter uses locks for thread-safety
private static var lock = NSLock()
private static var callbackHandlers: [String: (URL) -> Void] = [:]

// DeeplinkFetcher uses continuations for async/await
await withCheckedThrowingContinuation { continuation in
    // Register handler
    // Wait for callback
    // Resume continuation
}
```

### Best Practices

1. **Never Block Main Thread:** All operations are async
2. **No Shared Mutable State:** Except SolanaWalletAdapter (synchronized)
3. **Structured Concurrency:** Use async/await, not callbacks
4. **Cancellation Support:** Timeout handling for deeplink operations
5. **Thread-Safe by Design:** Value types eliminate data races

---

## Extensibility Points

### Adding New Wallets

```swift
struct MyWallet: DeeplinkWallet {
    static let _deeplinkWalletOptions = DeeplinkWalletOptions(
        scheme: "mywallet",
        pathPrefix: "/ul/v1"
    )

    // Wallet protocol conformance
    // All operations provided by DeeplinkWallet default implementations
}
```

### Adding New RPC Methods

```swift
extension SolanaRPCClient {
    func myCustomMethod() async throws -> MyResult {
        try await fetch(
            method: "myMethod",
            params: MyParams(...),
            responseType: MyResult.self
        )
    }
}
```

### Adding New Programs

```swift
enum MyProgram: Program {
    static let programId = try! PublicKey("MyProgramAddress")

    static func myInstruction(
        account1: PublicKey,
        account2: PublicKey,
        data: MyData
    ) -> Instruction {
        Instruction(
            programId: programId,
            accounts: [
                .init(publicKey: account1, isSigner: true, isWritable: true),
                .init(publicKey: account2, isSigner: false, isWritable: false)
            ],
            data: /* borsh-encoded data */
        )
    }
}
```

### Custom Storage Backend

```swift
class MyStorage: SecureStorage {
    func retrieve(key: String) async throws -> Data { /* ... */ }
    func store(_ data: Data, key: String) async throws { /* ... */ }
    func clear(key: String) async throws { /* ... */ }
    func retrieveAll() async throws -> [String: Data] { /* ... */ }
}

let manager = WalletConnectionManager(
    availableWallets: [...],
    storage: MyStorage()
)
```

---

## Performance Considerations

### Optimizations

1. **Lazy Initialization:** Wallets created only when needed
2. **Connection Reuse:** Persistent sessions avoid re-connection overhead
3. **Minimal Encoding:** Efficient Borsh serialization
4. **Cached Blockhashes:** Can reuse for ~60 seconds
5. **Parallel Requests:** Multiple wallets can operate concurrently

### Resource Usage

- **Memory:** Minimal - mostly value types on stack
- **Storage:** Small - only connection data (~200 bytes per wallet)
- **Network:** RPC calls only when explicitly requested
- **CPU:** Crypto operations (signing, DH) are fast (~1ms)

### Scalability

- **Multiple Wallets:** No limit on concurrent connections
- **Transaction Size:** Supports up to 1232 bytes (Solana limit)
- **Batch Operations:** `signAllTransactions` for multiple txs
- **RPC Batching:** Not currently implemented (future enhancement)

---

## Security Considerations

### Threat Model

**Protected Against:**
- Man-in-the-middle attacks (encrypted communication)
- Replay attacks (unique nonces)
- Tampering (authenticated encryption)
- Session hijacking (ephemeral keys)
- Key extraction (Keychain protection)

**Out of Scope:**
- Device compromise (can't protect against malware)
- Malicious wallet apps (user must trust wallet)
- Phishing (user must verify app identity)

### Security Best Practices

1. **Use `.whenUnlockedThisDeviceOnly`:** Default Keychain accessibility
2. **Validate Wallet Responses:** Type-safe parsing prevents injection
3. **Timeout Requests:** Prevent indefinite waiting
4. **Clear Sensitive Data:** Disconnect clears encryption keys
5. **No Key Logging:** Never log private keys or shared secrets

---

## Testing Strategy

### Unit Tests

- Pure functions (Base58, crypto operations)
- Transaction building logic
- Account ordering and deduplication
- Serialization/deserialization

### Integration Tests

- RPC client with devnet
- Transaction signing flow (requires manual wallet interaction)
- Connection recovery from storage

### Testability Features

- Protocol-based design (easy to mock)
- Dependency injection (custom storage)
- Value types (easy to construct test data)
- No hidden global state (except SolanaWalletAdapter)

---

## Future Enhancements

### Planned Features

1. **Web Wallets:** Browser extension integration
2. **Hardware Wallets:** Ledger support via Bluetooth
3. **More RPC Methods:** Complete Solana RPC coverage
4. **Transaction Simulation:** Pre-flight simulation results
5. **Account Subscriptions:** WebSocket-based account monitoring
6. **Batch RPC Requests:** Multiple RPC calls in one request

### Architectural Improvements

1. **Actor-Based Wallet Manager:** Replace locks with actors
2. **Observation Framework:** SwiftUI-friendly `@Observable` support
3. **Structured Logging:** os_log integration
4. **Metrics Collection:** Performance and usage analytics
5. **Advanced Error Recovery:** Automatic retry with exponential backoff

---

## See Also

- [Getting Started Guide](GettingStarted.md)
- [API Reference](API.md)
- [Transaction Building Guide](Transactions.md)
- [Examples](Examples.md)
