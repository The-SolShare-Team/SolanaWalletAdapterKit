import SwiftBorsh

@BorshEncodable
private struct EmptyData {}

public enum AssociatedTokenProgram: Program, Instruction {
    public static let programId: PublicKey = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"

    case createAssociatedTokenAccount(
        mint: PublicKey,
        associatedAccount: PublicKey,
        owner: PublicKey,
        payer: PublicKey,
        associatedProgramId: PublicKey = AssociatedTokenProgram.programId,
        tokenProgramId: PublicKey = TokenProgram.programId
    )

    public var accounts: [AccountMeta] {
        return switch self {
        case .createAssociatedTokenAccount(
            let mint, let associatedAccount, let owner, let payer, _, let tokenProgramId):
            [
                AccountMeta(publicKey: payer, isSigner: true, isWritable: true),
                AccountMeta(publicKey: associatedAccount, isSigner: false, isWritable: true),
                AccountMeta(publicKey: owner, isSigner: false, isWritable: false),
                AccountMeta(publicKey: mint, isSigner: false, isWritable: false),
                AccountMeta(publicKey: SystemProgram.programId, isSigner: false, isWritable: false),
                AccountMeta(publicKey: tokenProgramId, isSigner: false, isWritable: false),
                AccountMeta(
                    publicKey: TokenProgram.sysvarRentPubkey, isSigner: false, isWritable: false),
            ]
        }
    }

    public var data: BorshEncodable {
        return switch self {
        case .createAssociatedTokenAccount: EmptyData()
        }
    }
}
