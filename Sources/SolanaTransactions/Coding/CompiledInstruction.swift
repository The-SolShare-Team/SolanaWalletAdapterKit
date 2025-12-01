/// Represents the encoding of a single instruction within a multi-instruction `Message`,
/// which forms the core of a Solana ``Transaction``.
///
/// - Parameters:
///   - programIdIndex: The index in `account_keys` that points to the program
///     responsible for executing this instruction.
///   - accounts: Indices into the `account_keys` array that specify the accounts
///     this instruction depends on.
///   - data: The serialized instruction payload. This byte sequence indicates
///     which program instruction to run and includes any required information.
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
