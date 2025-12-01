import SwiftBorsh

@BorshEncodable
private struct TransferData {
    var index: Int32 { 2 }
    let lamports: Int64
}

@BorshEncodable
private struct CreateAccountData {
    var index: Int32 { 0 }
    let lamports: Int64
    let space: Int64
    let programId: PublicKey
}
///The System Program manages account creation and handles SOL transfers between accounts.
///
///
///For more information see [System Program](https://solana.com/docs/core/programs#the-system-program) Solana Docs.
///
/// The system program conforms to a program when building instructions for a transaction, but also conforms to an instruction for compilation purposes. For more information, view ``Instruction`` and ``Program``.
/// # Instructions:
/// - ``transfer(from:to:lamports:)``
/// - ``createAccount(from:newAccount:lamports:space:programId:)``
public enum SystemProgram: Program, Instruction {
    public static let programId: PublicKey = "11111111111111111111111111111111"

    /// Transfers SOL from one account to another.
    ///
    /// This instruction moves the specified number of lamports from the `from`
    /// account to the `to` account. The `from` account must sign the transaction
    /// and must have a sufficient balance to cover the transfer amount.
    ///
    /// - Parameters:
    ///   - from:
    ///       The account sending lamports. Must sign the transaction.
    ///
    ///   - to:
    ///       The recipient account receiving lamports.
    ///
    ///   - lamports:
    ///       The amount of SOL to transfer, expressed in lamports.
    ///       (1 SOL = 1_000_000_000 lamports)
    case transfer(from: PublicKey, to: PublicKey, lamports: Int64)
    
    
    /// Creates a new account on the Solana blockchain.
    ///
    /// This instruction allocates space, assigns ownership to a program, and
    /// funds the new account with enough lamports to be rent-exempt (or as
    /// specified).
    ///
    /// The `from` account pays for both the allocated lamports and the required
    /// rent exemption. The `newAccount` must be a signer and must not already
    /// exist on-chain.
    ///
    /// - Parameters:
    ///   - from:
    ///       The funding account responsible for paying lamports and rent in terms of PublicKey. Must sign the transaction.
    ///
    ///   - newAccount:
    ///       The new account to be created in terms of the Public Key. Must sign the transaction and must
    ///       be generated off-chain before sending the transaction.
    ///
    ///   - lamports:
    ///       The number of lamports to fund the new account with.
    ///       Typically set to the minimum rent-exempt balance for the
    ///       given `space`.
    ///
    ///   - space:
    ///       The number of bytes to allocate for the account’s data.
    ///
    ///   - programId:
    ///       The program the new account will be assigned to. This determines
    ///       which program owns and can modify the account.
    case createAccount(
        from: PublicKey, newAccount: PublicKey, lamports: Int64, space: Int64, programId: PublicKey)

    /// The ordered list of accounts required by the System Program
    /// instruction, in the exact order defined by the System program specification.
    ///
    /// This list varies depending on the specific instruction case
    ///  when constructing transactions via higher-level builders like
    /// ``InstructionsBuilder``.
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
    
    /// The Borsh-encoded instruction data for each System Program instruction.
    public var data: BorshEncodable {
        return switch self {
        case .transfer(_, _, let lamports): TransferData(lamports: lamports)
        case .createAccount(_, _, let lamports, let space, let programId):
            CreateAccountData(lamports: lamports, space: space, programId: programId)
        }
    }
}
