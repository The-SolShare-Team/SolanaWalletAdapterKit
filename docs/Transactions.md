# Transaction Building Guide

A comprehensive guide to building, signing, and sending Solana transactions using SolanaWalletAdapterKit.

## Table of Contents

- [Transaction Basics](#transaction-basics)
- [Instruction Builder DSL](#instruction-builder-dsl)
- [Common Patterns](#common-patterns)
- [System Program Operations](#system-program-operations)
- [Token Operations](#token-operations)
- [Associated Token Accounts](#associated-token-accounts)
- [Program Derived Addresses](#program-derived-addresses)
- [Advanced Topics](#advanced-topics)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Transaction Basics

### Transaction Structure

A Solana transaction consists of:

1. **Signatures**: Ed25519 signatures from required signers
2. **Message**: The transaction payload containing:
   - **Fee Payer**: Account paying transaction fees
   - **Recent Blockhash**: Proof of recency (valid ~60 seconds)
   - **Instructions**: List of program instructions to execute
   - **Account List**: All accounts involved in the transaction

### Creating a Basic Transaction

```swift
let transaction = try Transaction(
    feePayer: wallet.publicKey!,
    blockhash: blockhash
) {
    // Instructions go here
}
```

**Required Parameters:**
- `feePayer`: The account that will pay transaction fees
- `blockhash`: A recent blockhash from `getLatestBlockhash()`

**Optional Parameters:**
- `version`: `.legacy` (default) or `.v0` for versioned transactions

### Getting a Recent Blockhash

Always fetch a fresh blockhash before building transactions:

```swift
let rpc = SolanaRPCClient(endpoint: .mainnet)
let result = try await rpc.getLatestBlockhash()
let blockhash = result.blockhash
```

**Blockhash Validity:**
- Valid for approximately 60 seconds
- Can be reused for multiple transactions within validity window
- Expired blockhash = transaction rejected

---

## Instruction Builder DSL

SolanaWalletAdapterKit provides a declarative DSL for building instructions using Swift result builders.

### Single Instruction

```swift
let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
    SystemProgram.transfer(
        from: sender,
        to: recipient,
        lamports: 1_000_000
    )
}
```

### Multiple Instructions

```swift
let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
    SystemProgram.transfer(from: alice, to: bob, lamports: 1_000_000)
    SystemProgram.transfer(from: alice, to: charlie, lamports: 2_000_000)
    MemoProgram.publishMemo(account: alice, memo: "Batch payment")
}
```

### Conditional Instructions

```swift
let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
    SystemProgram.transfer(from: sender, to: recipient, lamports: amount)

    if includesMemo {
        MemoProgram.publishMemo(account: sender, memo: "Payment")
    }

    if isImportant {
        MemoProgram.publishMemo(account: sender, memo: "IMPORTANT")
    } else {
        MemoProgram.publishMemo(account: sender, memo: "Regular")
    }
}
```

### Loops

```swift
let recipients = ["Address1", "Address2", "Address3"]

let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
    for recipient in recipients {
        SystemProgram.transfer(
            from: sender,
            to: try! PublicKey(recipient),
            lamports: 1_000_000
        )
    }
}
```

**With Enumeration:**
```swift
let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
    for (index, recipient) in recipients.enumerated() {
        SystemProgram.transfer(
            from: sender,
            to: recipient,
            lamports: Int64(index + 1) * 1_000_000
        )
    }
}
```

### Switch Statements

```swift
enum PaymentType {
    case standard, priority, urgent
}

let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
    switch paymentType {
    case .standard:
        SystemProgram.transfer(from: sender, to: recipient, lamports: 1_000_000)
    case .priority:
        SystemProgram.transfer(from: sender, to: recipient, lamports: 2_000_000)
    case .urgent:
        SystemProgram.transfer(from: sender, to: recipient, lamports: 5_000_000)
    }
}
```

### Arrays of Instructions

```swift
let instructions = [
    SystemProgram.transfer(from: sender, to: recipient1, lamports: 1_000_000),
    SystemProgram.transfer(from: sender, to: recipient2, lamports: 2_000_000)
]

let tx = try Transaction(feePayer: feePayer, blockhash: blockhash) {
    instructions
}
```

### Combining Patterns

```swift
let tx = try Transaction(feePayer: wallet.publicKey!, blockhash: blockhash) {
    // Static instruction
    MemoProgram.publishMemo(account: wallet.publicKey!, memo: "Batch transfer")

    // Loop
    for recipient in recipients {
        SystemProgram.transfer(
            from: wallet.publicKey!,
            to: recipient.address,
            lamports: recipient.amount
        )
    }

    // Conditional
    if totalAmount > threshold {
        MemoProgram.publishMemo(
            account: wallet.publicKey!,
            memo: "Large transaction"
        )
    }

    // Array
    additionalInstructions
}
```

---

## Common Patterns

### Simple SOL Transfer

```swift
func transferSOL(
    from: PublicKey,
    to: PublicKey,
    lamports: UInt64,
    blockhash: Blockhash
) throws -> Transaction {
    try Transaction(feePayer: from, blockhash: blockhash) {
        SystemProgram.transfer(
            from: from,
            to: to,
            lamports: Int64(lamports)
        )
    }
}
```

### Multi-Recipient Payment

```swift
struct Recipient {
    let address: PublicKey
    let amount: UInt64
}

func batchPayment(
    from: PublicKey,
    recipients: [Recipient],
    blockhash: Blockhash
) throws -> Transaction {
    try Transaction(feePayer: from, blockhash: blockhash) {
        for recipient in recipients {
            SystemProgram.transfer(
                from: from,
                to: recipient.address,
                lamports: Int64(recipient.amount)
            )
        }
    }
}
```

### Transfer with Memo

```swift
func transferWithMemo(
    from: PublicKey,
    to: PublicKey,
    lamports: UInt64,
    memo: String,
    blockhash: Blockhash
) throws -> Transaction {
    try Transaction(feePayer: from, blockhash: blockhash) {
        SystemProgram.transfer(
            from: from,
            to: to,
            lamports: Int64(lamports)
        )
        MemoProgram.publishMemo(account: from, memo: memo)
    }
}
```

---

## System Program Operations

The System Program handles SOL transfers and account creation.

**Program ID:** `11111111111111111111111111111111`

### Transfer SOL

```swift
SystemProgram.transfer(
    from: PublicKey,
    to: PublicKey,
    lamports: Int64
)
```

**Parameters:**
- `from`: Source account (must sign transaction)
- `to`: Destination account
- `lamports`: Amount to transfer (1 SOL = 1,000,000,000 lamports)

**Example:**
```swift
// Transfer 0.1 SOL
SystemProgram.transfer(
    from: wallet.publicKey!,
    to: try! PublicKey("RecipientAddressHere"),
    lamports: 100_000_000
)
```

### Create Account

```swift
SystemProgram.createAccount(
    from: PublicKey,
    newAccount: PublicKey,
    lamports: Int64,
    space: UInt64,
    owner: PublicKey
)
```

**Parameters:**
- `from`: Funding account (pays for rent + allocation)
- `newAccount`: New account to create (must sign transaction)
- `lamports`: Initial balance (must cover rent exemption)
- `space`: Size in bytes to allocate
- `owner`: Program that will own this account

**Example:**
```swift
// Create a new account owned by Token Program
let newAccountKeypair = /* generate keypair */

SystemProgram.createAccount(
    from: wallet.publicKey!,
    newAccount: newAccountKeypair.publicKey,
    lamports: rentExemptBalance,
    space: 165, // Size of token account
    owner: TokenProgram.programId
)
```

---

## Token Operations

The Token Program handles SPL token operations.

**Program ID:** `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`

### Transfer Tokens

```swift
TokenProgram.transfer(
    source: PublicKey,
    destination: PublicKey,
    authority: PublicKey,
    amount: UInt64
)
```

**Parameters:**
- `source`: Source token account
- `destination`: Destination token account
- `authority`: Account authorized to transfer (must sign)
- `amount`: Amount in smallest unit (considering decimals)

**Example:**
```swift
// Transfer 100 tokens (assuming 6 decimals)
TokenProgram.transfer(
    source: sourceTokenAccount,
    destination: destTokenAccount,
    authority: wallet.publicKey!,
    amount: 100_000_000 // 100 * 10^6
)
```

### Transfer Tokens (Checked)

Safer version that validates decimals:

```swift
TokenProgram.transferChecked(
    source: PublicKey,
    mint: PublicKey,
    destination: PublicKey,
    authority: PublicKey,
    amount: UInt64,
    decimals: UInt8
)
```

**Example:**
```swift
TokenProgram.transferChecked(
    source: sourceTokenAccount,
    mint: tokenMintAddress,
    destination: destTokenAccount,
    authority: wallet.publicKey!,
    amount: 100_000_000,
    decimals: 6
)
```

### Initialize Mint

```swift
TokenProgram.initializeMint(
    mint: PublicKey,
    mintAuthority: PublicKey,
    freezeAuthority: PublicKey?,
    decimals: UInt8
)
```

**Example:**
```swift
// Create a new token with 9 decimals
TokenProgram.initializeMint(
    mint: newMintKeypair.publicKey,
    mintAuthority: wallet.publicKey!,
    freezeAuthority: wallet.publicKey!,
    decimals: 9
)
```

### Initialize Token Account

```swift
TokenProgram.initializeAccount(
    account: PublicKey,
    mint: PublicKey,
    owner: PublicKey
)
```

**Example:**
```swift
TokenProgram.initializeAccount(
    account: newTokenAccount,
    mint: tokenMintAddress,
    owner: wallet.publicKey!
)
```

### Mint Tokens

```swift
TokenProgram.mintTo(
    mint: PublicKey,
    destination: PublicKey,
    authority: PublicKey,
    amount: UInt64
)
```

**Example:**
```swift
// Mint 1000 tokens (with 6 decimals)
TokenProgram.mintTo(
    mint: tokenMintAddress,
    destination: destinationTokenAccount,
    authority: mintAuthority,
    amount: 1_000_000_000 // 1000 * 10^6
)
```

### Close Token Account

```swift
TokenProgram.closeAccount(
    account: PublicKey,
    destination: PublicKey,
    authority: PublicKey
)
```

**Example:**
```swift
// Close token account and return rent to wallet
TokenProgram.closeAccount(
    account: tokenAccountToClose,
    destination: wallet.publicKey!, // Receives remaining lamports
    authority: wallet.publicKey!
)
```

---

## Associated Token Accounts

Associated Token Accounts (ATAs) are deterministic token accounts derived from a wallet's public key and token mint.

**Program ID:** `ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL`

### Create Associated Token Account

```swift
AssociatedTokenProgram.createAssociatedTokenAccount(
    payer: PublicKey,
    associatedToken: PublicKey,
    owner: PublicKey,
    mint: PublicKey
)
```

**Parameters:**
- `payer`: Account paying for account creation
- `associatedToken`: The ATA address (derived)
- `owner`: Wallet that will own the token account
- `mint`: Token mint address

**Example:**
```swift
// 1. Calculate ATA address
let ata = try PublicKey.findProgramAddress(
    seeds: [
        owner.bytes,
        TokenProgram.programId.bytes,
        tokenMint.bytes
    ],
    programId: AssociatedTokenProgram.programId
).0

// 2. Create the ATA
AssociatedTokenProgram.createAssociatedTokenAccount(
    payer: wallet.publicKey!,
    associatedToken: ata,
    owner: wallet.publicKey!,
    mint: tokenMint
)
```

### Complete Token Transfer with ATA

```swift
func transferTokensWithATA(
    from: PublicKey,
    to: PublicKey,
    tokenMint: PublicKey,
    amount: UInt64,
    decimals: UInt8,
    blockhash: Blockhash
) throws -> Transaction {
    // Calculate ATAs
    let fromATA = try PublicKey.findProgramAddress(
        seeds: [
            from.bytes,
            TokenProgram.programId.bytes,
            tokenMint.bytes
        ],
        programId: AssociatedTokenProgram.programId
    ).0

    let toATA = try PublicKey.findProgramAddress(
        seeds: [
            to.bytes,
            TokenProgram.programId.bytes,
            tokenMint.bytes
        ],
        programId: AssociatedTokenProgram.programId
    ).0

    return try Transaction(feePayer: from, blockhash: blockhash) {
        // Create recipient's ATA if needed
        // Note: In production, check if ATA exists first
        AssociatedTokenProgram.createAssociatedTokenAccount(
            payer: from,
            associatedToken: toATA,
            owner: to,
            mint: tokenMint
        )

        // Transfer tokens
        TokenProgram.transferChecked(
            source: fromATA,
            mint: tokenMint,
            destination: toATA,
            authority: from,
            amount: amount,
            decimals: decimals
        )
    }
}
```

---

## Program Derived Addresses

PDAs are deterministic addresses derived from seeds and a program ID.

### Find PDA

```swift
let (pda, bump) = try PublicKey.findProgramAddress(
    seeds: [Data],
    programId: PublicKey
)
```

**Returns:**
- `pda`: The program derived address
- `bump`: The bump seed (0-255) that ensures the address is off-curve

**Example:**
```swift
let (vaultPDA, vaultBump) = try PublicKey.findProgramAddress(
    seeds: [
        "vault".data(using: .utf8)!,
        userPublicKey.bytes,
        tokenMint.bytes
    ],
    programId: myProgramId
)
```

### Create PDA with Known Bump

```swift
let pda = try PublicKey.createProgramAddress(
    seeds: [Data],
    programId: PublicKey
)
```

**Example:**
```swift
let pda = try PublicKey.createProgramAddress(
    seeds: [
        "vault".data(using: .utf8)!,
        userPublicKey.bytes,
        Data([bump]) // Include bump seed
    ],
    programId: myProgramId
)
```

### Common PDA Patterns

**Metadata PDA:**
```swift
let (metadataPDA, _) = try PublicKey.findProgramAddress(
    seeds: [
        "metadata".data(using: .utf8)!,
        metadataProgramId.bytes,
        mintPublicKey.bytes
    ],
    programId: metadataProgramId
)
```

**User State PDA:**
```swift
let (userStatePDA, _) = try PublicKey.findProgramAddress(
    seeds: [
        "user-state".data(using: .utf8)!,
        userPublicKey.bytes
    ],
    programId: myProgramId
)
```

**Vault PDA:**
```swift
let (vaultPDA, _) = try PublicKey.findProgramAddress(
    seeds: [
        "vault".data(using: .utf8)!,
        poolPublicKey.bytes,
        tokenMintPublicKey.bytes
    ],
    programId: myProgramId
)
```

---

## Advanced Topics

### Versioned Transactions (V0)

V0 transactions support address lookup tables for larger transactions:

```swift
let tx = try Transaction(
    feePayer: wallet.publicKey!,
    blockhash: blockhash,
    version: .v0  // Enable V0
) {
    // Instructions here
    // Can include more accounts via lookup tables
}
```

**Benefits:**
- Support for more accounts in a single transaction
- Reduced transaction size
- Lower fees for complex transactions

### Custom Program Instructions

```swift
// Define your program
enum MyProgram {
    static let programId = try! PublicKey("YourProgramIdHere")
}

// Create custom instruction
let instruction = Instruction(
    programId: MyProgram.programId,
    accounts: [
        .init(publicKey: account1, isSigner: true, isWritable: true),
        .init(publicKey: account2, isSigner: false, isWritable: true),
        .init(publicKey: account3, isSigner: false, isWritable: false)
    ],
    data: /* Borsh-encoded instruction data */
)

// Use in transaction
let tx = try Transaction(feePayer: wallet.publicKey!, blockhash: blockhash) {
    instruction
}
```

### Transaction Size Optimization

Solana transactions are limited to 1232 bytes. To optimize:

**1. Use Lookup Tables (V0 transactions):**
```swift
// V0 transactions can reference accounts via lookup tables
let tx = try Transaction(
    feePayer: feePayer,
    blockhash: blockhash,
    version: .v0
) {
    // More instructions possible with lookup tables
}
```

**2. Minimize Account Duplicates:**
```swift
// Automatic deduplication happens internally
// But be aware of account reuse
```

**3. Batch Operations:**
```swift
// Split large operations across multiple transactions
let transactions = recipients.chunked(into: 10).map { chunk in
    try! Transaction(feePayer: sender, blockhash: blockhash) {
        for recipient in chunk {
            SystemProgram.transfer(from: sender, to: recipient, lamports: amount)
        }
    }
}
```

### Compute Budget

Increase compute units for complex transactions:

```swift
// Note: Compute Budget program not yet implemented in SolanaWalletAdapterKit
// Example of how it would work:

enum ComputeBudgetProgram {
    static let programId = try! PublicKey("ComputeBudget111111111111111111111111111111")

    static func setComputeUnitLimit(units: UInt32) -> Instruction {
        // Implementation
    }

    static func setComputeUnitPrice(microLamports: UInt64) -> Instruction {
        // Implementation
    }
}

let tx = try Transaction(feePayer: wallet.publicKey!, blockhash: blockhash) {
    ComputeBudgetProgram.setComputeUnitLimit(units: 200_000)
    ComputeBudgetProgram.setComputeUnitPrice(microLamports: 1000)

    // Your complex instructions
}
```

---

## Best Practices

### 1. Always Use Fresh Blockhashes

```swift
// ✅ Good: Fresh blockhash for each transaction
let blockhash = try await rpc.getLatestBlockhash().blockhash
let tx = try Transaction(feePayer: wallet.publicKey!, blockhash: blockhash) {
    // ...
}

// ❌ Bad: Reusing old blockhash
let blockhash = cachedBlockhashFromMinutesAgo
```

### 2. Handle Transaction Failures

```swift
do {
    let result = try await wallet.signAndSendTransaction(
        transaction: tx,
        sendOptions: SendOptions(
            maxRetries: 3,
            skipPreflight: false,
            preflightCommitment: .confirmed
        )
    )
    print("Success: \(result.signature)")
} catch SolanaWalletAdapterError.userRejectedRequest {
    // User cancelled - don't show error
} catch SolanaWalletAdapterError.transactionRejected(let message) {
    // Transaction failed validation
    print("Transaction rejected: \(message)")
} catch {
    // Other errors
    print("Error: \(error)")
}
```

### 3. Validate Inputs

```swift
guard lamports > 0 else {
    throw ValidationError.invalidAmount
}

guard lamports <= maxTransferAmount else {
    throw ValidationError.amountTooLarge
}

// Validate addresses
let recipientKey = try PublicKey(recipientAddress)
```

### 4. Use Type-Safe Decimals

```swift
struct TokenAmount {
    let amount: UInt64
    let decimals: UInt8

    var lamports: UInt64 {
        amount * UInt64(pow(10.0, Double(decimals)))
    }
}

let amount = TokenAmount(amount: 100, decimals: 6)
TokenProgram.transfer(
    source: source,
    destination: dest,
    authority: authority,
    amount: amount.lamports
)
```

### 5. Add Memos for Tracking

```swift
let tx = try Transaction(feePayer: wallet.publicKey!, blockhash: blockhash) {
    SystemProgram.transfer(from: sender, to: recipient, lamports: amount)

    // Add memo for tracking
    MemoProgram.publishMemo(
        account: sender,
        memo: "Order #\(orderId) - \(Date())"
    )
}
```

### 6. Check Account Ownership

```swift
// Before transferring tokens, ensure accounts are valid token accounts
// This would typically be done via RPC getAccountInfo call

// Example pattern:
func validateTokenAccount(_ address: PublicKey) async throws -> Bool {
    // RPC call to verify account is owned by Token Program
    // and has correct data layout
}
```

### 7. Handle Rent Exemption

```swift
// Accounts must maintain minimum balance for rent exemption
// Calculate required lamports before creating accounts

let rentExemptBalance = try await rpc.getMinimumBalanceForRentExemption(
    dataLength: accountSize
)

SystemProgram.createAccount(
    from: payer,
    newAccount: newAccount,
    lamports: Int64(rentExemptBalance),
    space: accountSize,
    owner: programId
)
```

---

## Troubleshooting

### Transaction Rejected: "Blockhash not found"

**Cause:** Blockhash expired (older than ~60 seconds)

**Solution:** Fetch a fresh blockhash
```swift
let blockhash = try await rpc.getLatestBlockhash().blockhash
```

### Transaction Rejected: "Insufficient funds"

**Cause:** Account doesn't have enough SOL for transfer + fees

**Solution:** Ensure account has sufficient balance
```swift
// Always leave some SOL for fees
let maxTransferAmount = accountBalance - 5000 // Leave 0.000005 SOL for fee
```

### Transaction Rejected: "Account not found"

**Cause:** Referenced account doesn't exist

**Solution:** Create account first or verify address is correct
```swift
// For token accounts, create ATA first
AssociatedTokenProgram.createAssociatedTokenAccount(...)
```

### Transaction Too Large

**Cause:** Transaction exceeds 1232 byte limit

**Solution:** Use V0 transactions or split into multiple transactions
```swift
// Option 1: V0 transaction
let tx = try Transaction(
    feePayer: wallet.publicKey!,
    blockhash: blockhash,
    version: .v0
) { ... }

// Option 2: Split transactions
let batch1 = try Transaction(...) { /* first half */ }
let batch2 = try Transaction(...) { /* second half */ }
```

### "Invalid account data for instruction"

**Cause:** Account data doesn't match expected format

**Solution:** Ensure accounts are initialized properly
```swift
// Initialize token account before using
TokenProgram.initializeAccount(
    account: tokenAccount,
    mint: mint,
    owner: owner
)
```

### Signature Verification Failed

**Cause:** Missing required signature

**Solution:** Ensure all required signers are included
```swift
// Fee payer must sign
// Any account marked as signer must sign
// Check instruction account requirements
```

---

## Transaction Examples

### Complete SOL Transfer Example

```swift
func sendSOL(
    wallet: PhantomWallet,
    to recipient: String,
    amount: Double
) async throws -> String {
    let rpc = SolanaRPCClient(endpoint: .mainnet)

    // Convert SOL to lamports
    let lamports = UInt64(amount * 1_000_000_000)

    // Get recent blockhash
    let blockhash = try await rpc.getLatestBlockhash().blockhash

    // Build transaction
    let transaction = try Transaction(
        feePayer: wallet.publicKey!,
        blockhash: blockhash
    ) {
        SystemProgram.transfer(
            from: wallet.publicKey!,
            to: try PublicKey(recipient),
            lamports: Int64(lamports)
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

### Complete Token Transfer Example

```swift
func sendTokens(
    wallet: PhantomWallet,
    to recipient: PublicKey,
    mint: PublicKey,
    amount: UInt64,
    decimals: UInt8
) async throws -> String {
    let rpc = SolanaRPCClient(endpoint: .mainnet)

    // Calculate ATAs
    let fromATA = try PublicKey.findProgramAddress(
        seeds: [
            wallet.publicKey!.bytes,
            TokenProgram.programId.bytes,
            mint.bytes
        ],
        programId: AssociatedTokenProgram.programId
    ).0

    let toATA = try PublicKey.findProgramAddress(
        seeds: [
            recipient.bytes,
            TokenProgram.programId.bytes,
            mint.bytes
        ],
        programId: AssociatedTokenProgram.programId
    ).0

    // Get blockhash
    let blockhash = try await rpc.getLatestBlockhash().blockhash

    // Build transaction
    let transaction = try Transaction(
        feePayer: wallet.publicKey!,
        blockhash: blockhash
    ) {
        // Create recipient ATA if needed
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
            amount: amount,
            decimals: decimals
        )
    }

    // Sign and send
    let result = try await wallet.signAndSendTransaction(transaction: transaction)
    return result.signature
}
```

---

## See Also

- [Getting Started Guide](GettingStarted.md)
- [API Reference](API.md)
- [Examples](Examples.md)
- [Architecture](Architecture.md)
