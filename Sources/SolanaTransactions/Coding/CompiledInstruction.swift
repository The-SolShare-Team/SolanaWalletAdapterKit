public struct CompiledInstruction: Equatable {
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
