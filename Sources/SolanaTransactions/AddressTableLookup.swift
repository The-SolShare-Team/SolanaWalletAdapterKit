public struct AddressTableLookup: Equatable {
    let account: PublicKey
    let writableIndexes: [UInt8]
    let readOnlyIndexes: [UInt8]
}

extension AddressTableLookup: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        account = try PublicKey(fromSolanaTransaction: &buffer)
        writableIndexes = try [UInt8].init(fromSolanaTransaction: &buffer)
        readOnlyIndexes = try [UInt8].init(fromSolanaTransaction: &buffer)
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        try account.solanaTransactionEncode(to: &buffer)
        try writableIndexes.solanaTransactionEncode(to: &buffer)
        try readOnlyIndexes.solanaTransactionEncode(to: &buffer)
    }
}
