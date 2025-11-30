/// Represents the encoding of a single instruction within a multi-instruction `Message`,
/// which forms the core of a Solana ``Transaction``.
///
/// - Parameters:
///   - programIdIndex: An index into the `account_keys` array indicating the
///     address of the program that will process this instruction.
///   - accounts: A list of indices into the `account_keys` array. Each index
///     refers to an account required by this instruction.
///   - data: The raw encoded instruction data. This byte array identifies which
///     instruction to invoke within the program, along with any arguments.
///
/// ```swift
/// public init(programIdIndex: UInt8, accounts: [UInt8], data: [UInt8]) {
///     self.programIdIndex = programIdIndex
///     self.accounts = accounts
///     self.data = data
/// }
/// ```
public struct CompiledInstruction: Equatable, Sendable {
    public let programIdIndex: UInt8
    public let accounts: [UInt8]
    public let data: [UInt8]

    public init(programIdIndex: UInt8, accounts: [UInt8], data: [UInt8]) {
        self.programIdIndex = programIdIndex
        self.accounts = accounts
        self.data = data
    }
}

extension CompiledInstruction: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        programIdIndex = try UInt8(fromSolanaTransaction: &buffer)
        accounts = try [UInt8](fromSolanaTransaction: &buffer)
        data = try [UInt8](fromSolanaTransaction: &buffer)
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        try programIdIndex.solanaTransactionEncode(to: &buffer)
        try accounts.solanaTransactionEncode(to: &buffer)
        try data.solanaTransactionEncode(to: &buffer)
    }
}
