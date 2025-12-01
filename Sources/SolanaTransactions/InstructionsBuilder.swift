import Collections
import SwiftBorsh

/// Represents a Solana program instruction.
///
<<<<<<< HEAD
/// An instruction is  a function that anyone using the Solana network can call, where each instruction is used to perform a specific action.
///
/// For more information, see [Solana Docs](https://solana.com/docs/core/instructions).
=======
/// An instruction is essentially a public function that anyone using the Solana network can call. Each instruction is used to perform a specific action. The execution logic for instructions are stored on programs, where each program defines its own set of instructions.
>>>>>>> 656e57b (finished SolanaTransactions)
///
/// See ``AssociatedTokenProgram``, ``MemoProgram``, ``SystemProgram``, ``TokenProgram`` to find instructions that are available with the SDK.
///
/// ```
///public protocol Instruction {
///     var programId: PublicKey { get }
///     var accounts: [AccountMeta] { get }
///     var data: BorshEncodable { get }
///}
/// ```
/// - Parameters:
///   - programId:
///        Public key of the program that executes this instruction.
///   - accounts:
///       Metadata describing accounts that should be passed to the program. See ``AccountMeta`` for details on how to specify Accounts.
///   - data:
///       Opaque data passed to the program for its own interpretation.
///
public protocol Instruction {
    var programId: PublicKey { get }
    var accounts: [AccountMeta] { get }
    var data: BorshEncodable { get }
}

/// Metadata about an account used in a Solana transaction instruction.
///
/// Each instruction in Solana specifies the accounts it will interact with.
/// `AccountMeta` defines the role of each account in that instruction, including
/// whether it signs the transaction and whether it can be modified.
///
/// - Parameters:
///   - publicKey:
///        The account's public key.
///   - isSigner:
///       A boolean value, where if true if this account must sign the transaction.
///   - isWritable:
///       A boolean value, where if true if the instruction may modify the account.
public struct AccountMeta {
    let publicKey: PublicKey
    let isSigner: Bool
    let isWritable: Bool

    public init(publicKey: PublicKey, isSigner: Bool, isWritable: Bool) {
        self.publicKey = publicKey
        self.isSigner = isSigner
        self.isWritable = isWritable
    }
}

/// A result builder for constructing arrays of `Instruction`s in a declarative DSL style.
///
/// This allows you to write multiple instructions in a closure and have them automatically
/// combined into a single array of instructions, which can then be used to build a `Transaction`.
///
/// See ``AssociatedTokenProgram``, ``MemoProgram``, ``SystemProgram``, ``TokenProgram`` to find instructions that are available with the SDK.
@resultBuilder
public enum InstructionsBuilder {
    public static func buildExpression(_ instruction: Instruction) -> [Instruction] {
        [instruction]
    }

    public static func buildBlock(_ instructions: [Instruction]...) -> [Instruction] {
        instructions.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Instruction]?) -> [Instruction] {
        component ?? []
    }

    public static func buildEither(first component: [Instruction]) -> [Instruction] {
        component
    }

    public static func buildEither(second component: [Instruction]) -> [Instruction] {
        component
    }

    public static func buildArray(_ components: [[Instruction]]) -> [Instruction] {
        components.flatMap { $0 }
    }
}

extension Transaction {
    /// Initializes a Solana transaction from a fee payer, a recent blockhash, and a
    /// list of instructions provided via a result builder.
    ///
    /// - Parameters:
    ///   - feePayer: The account responsible for paying transaction fees. Must be a signer.
    ///   - blockhash: A recent blockhash fetched from the cluster to make the transaction valid and prevent replay. See RPC.getLatestBlockhash in SolanaRPC.
    ///   - instructionsBuilder: A closure returning a list of `Instruction`s using the `@InstructionsBuilder` DSL. See ``InstructionsBuilder``
    ///
    /// # Example
    /// ```swift
    /// let tr = try Transaction(
    ///     feePayer: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
    ///     blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk"
    /// ) {
    ///     for i in 0..<3 {
    ///         SystemProgram.transfer(
    ///             from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
    ///             to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
    ///             lamports: Int64(i)
    ///         )
    ///     }
    ///
    ///     if true {
    ///         MemoProgram.publishMemo(
    ///             account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
    ///             memo: "abc"
    ///         )
    ///     }
    /// }
    /// ```
    ///
    /// In this example:
    /// 1. A fee payer and a recent blockhash are specified for the transaction.
    /// 2. Multiple instructions are added dynamically using a loop.
    /// 3. Instructions can be conditionally included using standard Swift control flow.
    /// 4. The `InstructionsBuilder` automatically combines all instructions into a single array, which is processed by the transaction initializer to build the account list and message.
    ///
    /// Afterwards, a `Transaction` object is created, containing the `signatures` placeholders and the compiled `message` ready for signing and submission to the network. See ``Transaction``
    public init(
        feePayer: PublicKey,
        blockhash: Blockhash, @InstructionsBuilder _ instructionsBuilder: () -> [Instruction]
    ) throws {
        let instructions = instructionsBuilder()

        // Fee payer is always a writable signer, and must be the first account
        var writableSigners: OrderedSet<PublicKey> = [feePayer]
        var readOnlySigners: OrderedSet<PublicKey> = []
        var writableNonSigners: OrderedSet<PublicKey> = []
        var readOnlyNonSigners: OrderedSet<PublicKey> = []
        var programIds: OrderedSet<PublicKey> = []

        for instruction in instructions {
            for account in instruction.accounts {
                switch (account.isSigner, account.isWritable) {
                case (true, true): writableSigners.append(account.publicKey)
                case (true, false): readOnlySigners.append(account.publicKey)
                case (false, true): writableNonSigners.append(account.publicKey)
                case (false, false): readOnlyNonSigners.append(account.publicKey)
                }
            }
            programIds.append(instruction.programId)
        }

        readOnlyNonSigners.formUnion(programIds)

        let signers = writableSigners.union(readOnlySigners)
        let accounts = signers.union(writableNonSigners).union(readOnlyNonSigners).union(programIds)

        let compiledInstructions = try instructions.map {
            CompiledInstruction(
                programIdIndex: UInt8(accounts.firstIndex(of: $0.programId)!),
                accounts: $0.accounts.map { UInt8(accounts.firstIndex(of: $0.publicKey)!) },
                data: try BorshEncoder.encode($0.data))
        }

        signatures = Array(repeating: Signature.placeholder, count: signers.count)

        message = .legacyMessage(
            LegacyMessage(
                signatureCount: UInt8(signers.count),
                readOnlyAccounts: UInt8(readOnlySigners.count),
                readOnlyNonSigners: UInt8(readOnlyNonSigners.count),
                accounts: Array(accounts), blockhash: blockhash, instructions: compiledInstructions
            ))
    }
}
