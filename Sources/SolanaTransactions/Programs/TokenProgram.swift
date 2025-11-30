import SwiftBorsh

private struct InitializeMintData {
    var index: UInt8 { 0 }
    let decimals: UInt8
    let mintAuthority: PublicKey
    let freezeAuthority: PublicKey?
}

extension InitializeMintData: BorshEncodable {
    public func borshEncode(to buffer: inout BorshByteBuffer) throws(BorshEncodingError) {
        try index.borshEncode(to: &buffer)
        try decimals.borshEncode(to: &buffer)
        try mintAuthority.borshEncode(to: &buffer)
        if let freezeAuthority = self.freezeAuthority {
            try UInt8(1).borshEncode(to: &buffer)
            try freezeAuthority.borshEncode(to: &buffer)
        } else {
            try UInt8(0).borshEncode(to: &buffer)
            try PublicKey.zero.borshEncode(to: &buffer)
        }
    }
}

@BorshEncodable
private struct InitializeAccountData {
    var index: UInt8 { 1 }
}

@BorshEncodable
private struct TransferData {
    var index: UInt8 { 3 }
    let amount: Int64
}

@BorshEncodable
private struct MintToData {
    var index: UInt8 { 7 }
    let amount: Int64
}

@BorshEncodable
private struct CloseAccountData {
    var index: UInt8 { 9 }
}

@BorshEncodable
private struct TransferCheckedData {
    var index: UInt8 { 12 }
    let amount: Int64
    let decimals: UInt8
}

/// Token Programs contain all instruction logic for interacting with tokens on the network (both fungible and non-fungible).
/// 
///  The memo program conforms to a program when building instructions for a transaction, but also conforms to an instruction for compilation purposes. For more information, view ``Instruction`` and ``Program``.
///  For more information, refer to [Solana Docs](https://solana.com/docs/tokens#token-program).
/// 
///  # Instructions
///  - ``initializeMint(mintAccount:decimals:mintAuthority:freezeAuthority:)``
///  - ``initializeAccount(account:mint:owner:)``
///  - ``transfer(from:to:amount:owner:)``
///  - ``mintTo(mint:destination:mintAuthority:amount:)``
///  - ``closeAccount(account:destination:owner:)``
///  - ``transferChecked(from:to:amount:decimals:owner:mint:)``
public enum TokenProgram: Program, Instruction {
    public static let programId: PublicKey = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
    public static let sysvarRentPubkey: PublicKey = "SysvarRent111111111111111111111111111111111"

    /// Creates a new SPL Token mint account.
    ///
    ///You need invoke two instructions to create a mint account:
    ///1. System Program: Create an account with allocated space for a mint account and transfer ownership to the Token Program.
    ///2. Token Program: Initialize the mint account data
    ///
    /// - Parameters:
    ///   - mintAccount:
    ///       The public key of the account that will *store the mint data*.
    ///
    ///   - decimals:
    ///       Number of base 10 digits to the right of the decimal place.
    ///
    ///   - mintAuthority:
    ///       The authority/multisignature to mint tokens.
    ///
    ///   - freezeAuthority:
    ///        The freeze authority/multisignature of the mint.
    case initializeMint(
        mintAccount: PublicKey,
        decimals: UInt8,
        mintAuthority: PublicKey,
        freezeAuthority: PublicKey? = nil,
    )
    
    /// Initializes a new SPL token account.
    ///
    /// A token account stores your balance of a specific token. Each token account is associated with exactly one mint and tracks your token balance and additional details.
    ///
    /// To hold tokens, you need a token account for that specific mint. Each token account tracks:
    /// - **Mint**: The specific token type it holds
    /// - **Owner**: The authority who can transfer tokens from this account
    ///
    /// - Parameters:
    ///   - mint:
    ///        The mint this account will hold tokens for.
    ///   - account:
    ///       The token account to initialize. Must be writable.
    ///   - owner:
    ///       The new account's owner/multisignature.
    case initializeAccount(
        account: PublicKey,
        mint: PublicKey,
        owner: PublicKey,
    )
    
    ///Token transfers move tokens between token accounts of the same mint.
    ///
    /// - Both token accounts must hold the same token type (mint)
    /// - Only the source account owner or delegate can authorize transfers
    ///
    /// - Parameters:
    ///   - from:
    ///        The source token account from where the token will be sent. Must be owned by `owner`.
    ///   - to:
    ///       The destination token account. Must be writable..
    ///   - amount:
    ///       The raw number of tokens to transfer.
    ///   - owner:
    ///       The authority allowed to spend tokens from the `from` account.
    case transfer(
        from: PublicKey,
        to: PublicKey,
        amount: Int64,
        owner: PublicKey,
    )
    
    ///Creates new units of a token into a token account
    ///
    /// - Only the mint authority can mint new tokens
    /// - A destination token account must exist to receive the minted tokens
    ///
    /// - Parameters:
    ///   - mint:
    ///        The mint account from which new tokens will be created.
    ///   - destination:
    ///         The token account that will receive the newly minted tokens.
    ///   - mintAuthority:
    ///       The number of tokens to mint, in base units.
    ///   - amount:
    ///       The authority allowed to mint tokens for this mint..
    case mintTo(
        mint: PublicKey,
        destination: PublicKey,
        mintAuthority: PublicKey,
        amount: Int64,
    )
    
    /// Permanently closes a token account and transfers all remaining SOL (rent) to a specified destination account
    ///
    /// The token account balance must be zero before closing. Only the token account owner or designated close authority can execute this instruction.
    ///
    /// - Parameters:
    ///   - account:
    ///        The token account to close.
    ///   - destination:
    ///         The account that will receive the reclaimed lamports.
    ///   - owner:
    ///       The authority allowed to close the token account.
    case closeAccount(
        account: PublicKey,
        destination: PublicKey,
        owner: PublicKey,
    )
    
    /// Transfers tokens between accounts, **with mint decimals checked**.
    ///
    /// `transferChecked` ensures:
    /// - the mint matches the token accounts
    /// - the amount aligns with the mint's decimal precision
    ///
    /// - Parameters:
    ///   - from:
    ///        The source token account from where the token will be sent. Must be owned by `owner`.
    ///   - to:
    ///       The destination token account. Must be writable..
    ///   - amount:
    ///       The raw number of tokens to transfer.
    ///   - decimals:
    ///       The number of decimal places defined by the mint.
    ///   - mint:
    ///       The mint associated with the token accounts.
    ///   - owner:
    ///       The authority allowed to spend tokens from the `from` account.
    case transferChecked(
        from: PublicKey,
        to: PublicKey,
        amount: Int64,
        decimals: UInt8,
        owner: PublicKey,
        mint: PublicKey,
    )

    /// The ordered list of accounts required by each Token Program
    /// instruction, in the exact order defined by the Token program specification.
    ///
    /// This list varies depending on the specific instruction case
    ///  when constructing transactions via higher-level builders like
    /// ``InstructionsBuilder``.
    public var accounts: [AccountMeta] {
        return switch self {
        case .initializeMint(let mintAccount, _, _, _):
            [
                AccountMeta(publicKey: mintAccount, isSigner: false, isWritable: true),
                AccountMeta(publicKey: Self.sysvarRentPubkey, isSigner: false, isWritable: false),
            ]
        case .initializeAccount(let account, let mintAccount, let owner):
            [
                AccountMeta(publicKey: account, isSigner: false, isWritable: true),
                AccountMeta(publicKey: mintAccount, isSigner: false, isWritable: false),
                AccountMeta(publicKey: owner, isSigner: false, isWritable: false),
                AccountMeta(publicKey: Self.sysvarRentPubkey, isSigner: false, isWritable: false),
            ]
        case .transfer(let from, let to, _, let owner):
            [
                AccountMeta(publicKey: from, isSigner: false, isWritable: true),
                AccountMeta(publicKey: to, isSigner: false, isWritable: true),
                AccountMeta(publicKey: owner, isSigner: true, isWritable: false),
            ]
        case .mintTo(let mint, let destination, let mintAuthority, _):
            [
                AccountMeta(publicKey: mint, isSigner: false, isWritable: true),
                AccountMeta(publicKey: destination, isSigner: false, isWritable: true),
                AccountMeta(publicKey: mintAuthority, isSigner: true, isWritable: false),
            ]
        case .closeAccount(let account, let destination, let owner):
            [
                AccountMeta(publicKey: account, isSigner: false, isWritable: true),
                AccountMeta(publicKey: destination, isSigner: false, isWritable: true),
                AccountMeta(publicKey: owner, isSigner: true, isWritable: false),
            ]
        case .transferChecked(let from, let to, _, _, let owner, let mint):
            [
                AccountMeta(publicKey: from, isSigner: false, isWritable: true),
                AccountMeta(publicKey: mint, isSigner: false, isWritable: false),
                AccountMeta(publicKey: to, isSigner: false, isWritable: true),
                AccountMeta(publicKey: owner, isSigner: true, isWritable: false),
            ]
        }
    }

    /// The Borsh-encoded instruction data for each Token Program instruction.
    public var data: BorshEncodable {
        return switch self {
        case .initializeMint(_, let decimals, let mintAuth, let freezeAuth):
            InitializeMintData(
                decimals: decimals,
                mintAuthority: mintAuth,
                freezeAuthority: freezeAuth
            )

        case .initializeAccount:
            InitializeAccountData()

        case .transfer(_, _, let amount, _):
            TransferData(amount: amount)

        case .mintTo(_, _, _, let amount):
            MintToData(amount: amount)

        case .closeAccount:
            CloseAccountData()

        case .transferChecked(_, _, let amount, let decimals, _, _):
            TransferCheckedData(amount: amount, decimals: decimals)
        }
    }
}
