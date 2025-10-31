// import SwiftBorsh

// public enum AssociatedTokenProgram: Instruction {
//     case createAssociatedTokenAccount(mint: PublicKey,
//         associatedAccount: PublicKey,
//         owner: PublicKey,
//         payer: PublicKey,
//         associatedProgramId: PublicKey = programId,
//         programId: PublicKey = TokenProgram.PROGRAM_ID)

//     public var accounts: [AccountMeta] {
//         return switch self {
//         case .publishMemo(let account, _):
//             [
//                 AccountMeta(publicKey: account, isSigner: true, isWritable: true)
//             ]
//         }
//     }

//     public var data: BorshEncodable {
//         switch self {
//         case .publishMemo(_, let memo): memo
//         }
//     }
// }

import Foundation
import SwiftBorsh

public enum AssociatedTokenProgram: Instruction {
    case createAssociatedTokenAccount(
        mint: PublicKey,
        associatedAccount: PublicKey,
        owner: PublicKey,
        payer: PublicKey,
        associatedProgramId: PublicKey = AssociatedTokenProgram.programId,
        tokenProgramId: PublicKey = TokenProgram.programId
    )

    // MARK: - Instruction Conformance

    // public var programId: PublicKey {
    //     switch self {
    //     case .createAssociatedTokenAccount(_, _, _, _, let associatedProgramId, _):
    //         return associatedProgramId
    //     }
    // }

    public var programId: PublicKey {
        return "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
    }

    public var accounts: [AccountMeta] {
        switch self {
        case .createAssociatedTokenAccount(
            let mint, let associatedAccount, let owner, let payer, _, let tokenProgramId):
            return [
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
        // No data for this instruction — equivalent to Kotlin's `byteArrayOf()`
        EmptyData()
    }
}

// MARK: - Helper Type for Empty Payloads

/// Represents an empty Borsh-encodable payload (`byteArrayOf()` in Kotlin)
@BorshEncodable
private struct EmptyData {}

// MARK: - Related Programs

extension SystemProgram {
    public static let programId = PublicKey(string: "11111111111111111111111111111111")
}
