public struct CompiledInstruction: Equatable {
    let programIdIndex: UInt8
    let accounts: [UInt8]
    let data: [UInt8]
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
