extension UInt8: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        guard let value: UInt8 = buffer.readInteger() else { throw .endOfBuffer }
        self = value
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        buffer.writeInteger(self)
    }
}
