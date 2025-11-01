extension UInt16: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        var result: UInt16 = 0
        var shift = 0

        for _ in 0..<3 {
            guard let byte: UInt8 = buffer.readInteger() else { throw .endOfBuffer }
            result |= UInt16(byte & 0x7F) << shift
            if (byte & 0x80) == 0 {
                self = result
                return
            }
            shift += 7
        }

        throw .invalidValue
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        var value = self
        while value >= 0x80 {
            let low7 = UInt8(value & 0x7F)
            buffer.writeInteger(low7 | UInt8(0x80))
            value >>= 7
        }
        buffer.writeInteger(UInt8(value))
    }
}
