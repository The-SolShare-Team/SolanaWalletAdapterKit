# Contributing

## Setup

```bash
git clone https://github.com/YOUR-USERNAME/SolanaWalletAdapterKit.git
cd SolanaWalletAdapterKit
swift build
swift test
```

## Development

### Branch

```bash
git checkout -b feature/your-feature
```

### Commit

```
<type>: <subject>

<body>
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `chore`

Example:
```
feat: Add Ledger wallet support

Implement hardware wallet integration via Bluetooth.

Closes #123
```

### Code Style

```swift
// Types: UpperCamelCase
struct PublicKey { }

// Functions/vars: lowerCamelCase
func signTransaction() { }
let isConnected = false

// Document public APIs
/// Transfers SOL between accounts.
public static func transfer(from: PublicKey, to: PublicKey, lamports: Int64) -> Instruction
```

### Testing

```bash
swift test
swift test --filter Base58Tests
swift test --enable-code-coverage
```

## Pull Request

1. Add tests
2. Update docs
3. Run tests
4. Create PR

Required for merge:
- [ ] Tests pass
- [ ] Code follows style guide
- [ ] Documentation updated
- [ ] One maintainer approval

## Adding Features

### New Wallet

```swift
public struct MyWallet: DeeplinkWallet {
    public static let _deeplinkWalletOptions = DeeplinkWalletOptions(
        scheme: "mywallet",
        pathPrefix: "/ul/v1"
    )

    public var connection: DeeplinkWalletConnection?
    public let appIdentity: AppIdentity
    public let cluster: Cluster

    public init(for appIdentity: AppIdentity, cluster: Cluster) {
        self.appIdentity = appIdentity
        self.cluster = cluster
    }
}
```

### New RPC Method

```swift
extension SolanaRPCClient {
    public func getBlock(slot: UInt64) async throws -> GetBlockResponse {
        try await fetch(method: "getBlock", params: [slot], responseType: GetBlockResponse.self)
    }
}
```

### New Program

```swift
public enum MyProgram: Program {
    public static let programId = try! PublicKey("ProgramAddress...")

    public static func myInstruction(account: PublicKey) -> Instruction {
        Instruction(
            programId: programId,
            accounts: [.init(publicKey: account, isSigner: true, isWritable: true)],
            data: /* encoded data */
        )
    }
}
```

## Issues

**Bug Report:**
- Description
- Steps to reproduce
- Expected vs actual behavior
- Environment (iOS/macOS version, Xcode version, wallet app)

**Feature Request:**
- What feature?
- Why needed?
- Proposed solution
