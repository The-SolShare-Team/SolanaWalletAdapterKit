import SwiftBorsh

@BorshEncodable
private struct EmptyData {}

///An associated token account (ATA) is the default token account for a wallet to hold a specific token.
///
/// Associated Token Accounts are derived using the wallet address and token mint
/// via a program-derived address (PDA), ensuring each wallet–mint pair has a
/// stable, predictable token account.
///
/// This enum defines the available instructions for the ATA program, including
/// creating a new associated token account when one does not already exist.
///
///
/// The associated token program conforms to a program when building instructions for a transaction, but also conforms to an instruction for compilation purposes. For more information, view ``Instruction`` and ``Program``.
///
/// For more details on ATAs, see:
/// https://solana.com/docs/tokens/basics/create-token-account
///
/// ## Instructions
/// - ``createAssociatedTokenAccount(mint:associatedAccount:owner:payer:associatedProgramId:tokenProgramId:)``
///
///
public enum AssociatedTokenProgram: Program, Instruction {
    public static let programId: PublicKey = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"

    /// Creates an instruction to generate an associated token account (ATA)
    /// for a given wallet and token mint.
    ///
    /// The associated token account is a PDA derived from:
    /// - the wallet's public key
    /// - the token mint address
    /// - the Associated Token Program ID
    ///
    /// If the account does not already exist, this instruction will allocate,
    /// initialize, and assign it to the SPL Token Program. If it already exists,
    /// the transaction will safely succeed without modifying it.
    ///
    /// - Parameters:
    ///   - mint:
    ///       The SPL token mint for which the associated token account is being created.
    ///
    ///   - associatedAccount:
    ///       The PDA-derived associated token account address that will be created.
    ///       This must be computed using the canonical ATA derivation formula.
    ///
    ///   - owner:
    ///       The wallet address that will own the associated token account.
    ///       Must be the wallet used when deriving `associatedAccount`.
    ///
    ///   - payer:
    ///       The account responsible for paying rent and allocation fees to create
    ///       the associated token account.
    ///
    ///   - associatedProgramId:
    ///       The program ID of the Associated Token Account program.
    ///       Defaults to ``AssociatedTokenProgram/programId``.
    ///
    ///   - tokenProgramId:
    ///       The SPL Token Program ID used to initialize and manage the token account.
    ///       Defaults to ``TokenProgram/programId``.
    case createAssociatedTokenAccount(
        mint: PublicKey,
        associatedAccount: PublicKey,
        owner: PublicKey,
        payer: PublicKey,
        associatedProgramId: PublicKey = AssociatedTokenProgram.programId,
        tokenProgramId: PublicKey = TokenProgram.programId
    )

    /// The ordered list of accounts required by the Associated Token Account (ATA)
    /// instruction, in the exact order defined by the ATA program specification.
    ///
    /// This list varies depending on the specific instruction case
    ///  when constructing transactions via higher-level builders like
    /// ``InstructionsBuilder``.
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
                AccountMeta(publicKey: TokenProgram.sysvarRentPubkey, isSigner: false, isWritable: false),
            ]
        }
    }

    /// The Borsh-encoded instruction data for the ATA instruction, which is empty in this instance.
    public var data: BorshEncodable {
        return switch self {
        case .createAssociatedTokenAccount: EmptyData()
        }
    }
}
