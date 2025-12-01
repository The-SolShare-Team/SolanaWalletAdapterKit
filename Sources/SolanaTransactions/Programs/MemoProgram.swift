import SwiftBorsh

/// A program that attaches a UTF-8 encoded text message, or "memo," to a transaction on the Solana blockchain.
///
/// For more information on th memo program, refer to  [Solana Docs](https://www.solana-program.com/docs/memo).
///
/// The memo program conforms to a program when building instructions for a transaction, but also conforms to an instruction for compilation purposes. For more information, view ``Instruction`` and ``Program``.
///
/// ## Instructions
/// - ``publishMemo(account:memo:)``
public enum MemoProgram: Program, Instruction {
    public static let programId: PublicKey = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"

    /// Publishes a UTF-8 memo string to the Solana blockchain using the Memo Program.
    ///
    /// - Parameters:
    ///   - account:
    ///       The signer in terms of a Public Key responsible for publishing the memo. The account must sign the transaction to authenticate the message.
    ///   - memo:
    ///       The UTF-8 encoded string to store on-chain.
    case publishMemo(account: PublicKey, memo: String)

    /// The ordered list of accounts required by the Memo Program
    /// instruction, in the exact order defined by the Memo program specification.
    ///
    /// This list varies depending on the specific instruction case
    ///  when constructing transactions via higher-level builders like
    /// ``InstructionsBuilder``.
    public var accounts: [AccountMeta] {
        return switch self {
        case .publishMemo(let account, _):
            [
                AccountMeta(publicKey: account, isSigner: true, isWritable: true)
            ]
        }
    }

    /// The Borsh-encoded instruction data for the Memo instruction, which is just the memo itself.
    public var data: BorshEncodable {
        switch self {
        case .publishMemo(_, let memo): memo
        }
    }
}
