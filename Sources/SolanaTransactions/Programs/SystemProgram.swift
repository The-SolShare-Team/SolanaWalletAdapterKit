import SwiftBorsh

@BorshEncodable
private struct TransferData {
    let index: Int32 = 2
    let lamports: Int64
}

@BorshEncodable
private struct CreateAccountData {
    let index: Int32 = 0
    let lamports: Int64
    let space: Int64
    let programId: PublicKey
}

public enum SystemProgram: Program, Instruction {
    public static let programId: PublicKey = "11111111111111111111111111111111"

    case transfer(from: PublicKey, to: PublicKey, lamports: Int64)
    case createAccount(
        from: PublicKey, newAccount: PublicKey, lamports: Int64, space: Int64, programId: PublicKey)

    public var accounts: [AccountMeta] {
        return switch self {
        case .transfer(let from, let to, _):
            [
                AccountMeta(publicKey: from, isSigner: true, isWritable: true),
                AccountMeta(publicKey: to, isSigner: false, isWritable: true),
            ]
        case .createAccount(let from, let new, _, _, _):
            [
                AccountMeta(publicKey: from, isSigner: true, isWritable: true),
                AccountMeta(publicKey: new, isSigner: true, isWritable: true),
            ]
        }
    }

    public var data: BorshEncodable {
        return switch self {
        case .transfer(_, _, let lamports): TransferData(lamports: lamports)
        case .createAccount(_, _, let lamports, let space, let programId):
            CreateAccountData(lamports: lamports, space: space, programId: programId)
        }
    }
}
