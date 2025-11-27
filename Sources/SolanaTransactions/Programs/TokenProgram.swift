import SwiftBorsh

private struct InitializeMintData {
    let index: UInt8 = 0
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
    let index: UInt8 = 2
}

@BorshEncodable
private struct TransferData {
    let index: UInt8 = 3
    let amount: Int64
}

@BorshEncodable
private struct MintToData {
    let index: UInt8 = 7
    let amount: Int64
}

@BorshEncodable
private struct CloseAccountData {
    let index: UInt8 = 9
}

@BorshEncodable
private struct TransferCheckedData {
    let index: UInt8 = 12
    let amount: Int64
    let decimals: UInt8
}

public enum TokenProgram: Program, Instruction {
    public static let programId: PublicKey = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
    public static let sysvarRentPubkey: PublicKey = "SysvarRent111111111111111111111111111111111"

    case initializeMint(
        mintAccount: PublicKey,
        decimals: UInt8,
        mintAuthority: PublicKey,
        freezeAuthority: PublicKey? = nil,
    )
    case initializeAccount(
        account: PublicKey,
        mint: PublicKey,
        owner: PublicKey,
    )
    case transfer(
        from: PublicKey,
        to: PublicKey,
        amount: Int64,
        owner: PublicKey,
    )
    case mintTo(
        mint: PublicKey,
        destination: PublicKey,
        mintAuthority: PublicKey,
        amount: Int64,
    )
    case closeAccount(
        account: PublicKey,
        destination: PublicKey,
        owner: PublicKey,
    )
    case transferChecked(
        from: PublicKey,
        to: PublicKey,
        amount: Int64,
        decimals: UInt8,
        owner: PublicKey,
        mint: PublicKey,
    )

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
                AccountMeta(publicKey: owner, isSigner: false, isWritable: true),
                AccountMeta(publicKey: Self.sysvarRentPubkey, isSigner: false, isWritable: false),
            ]
        case .transfer(let from, let to, _, let owner):
            [
                AccountMeta(publicKey: from, isSigner: false, isWritable: true),
                AccountMeta(publicKey: to, isSigner: false, isWritable: true),
                AccountMeta(publicKey: owner, isSigner: true, isWritable: true),
            ]
        case .mintTo(let mint, let destination, let mintAuthority, _):
            [
                AccountMeta(publicKey: mint, isSigner: false, isWritable: true),
                AccountMeta(publicKey: destination, isSigner: false, isWritable: true),
                AccountMeta(publicKey: mintAuthority, isSigner: true, isWritable: true),
            ]
        case .closeAccount(let account, let destination, let owner):
            [
                AccountMeta(publicKey: account, isSigner: false, isWritable: true),
                AccountMeta(publicKey: destination, isSigner: false, isWritable: true),
                AccountMeta(publicKey: owner, isSigner: true, isWritable: true),
            ]
        case .transferChecked(let from, let to, _, _, let owner, let mint):
            [
                AccountMeta(publicKey: from, isSigner: false, isWritable: true),
                AccountMeta(publicKey: mint, isSigner: false, isWritable: false),
                AccountMeta(publicKey: to, isSigner: false, isWritable: true),
                AccountMeta(publicKey: owner, isSigner: true, isWritable: true),
            ]
        }
    }

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
