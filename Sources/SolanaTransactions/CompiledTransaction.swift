public struct CompiledTransaction: Equatable {
    public let signatures: [Signature]
    public let message: CompiledVersionedMessage
}

extension CompiledTransaction {
    public func encode() throws(SolanaTransactionCodingError) -> [UInt8] {
        var buffer = SolanaTransactionBuffer()
        try signatures.solanaTransactionEncode(to: &buffer)
        try message.solanaTransactionEncode(to: &buffer)
        return buffer.readBytes(length: buffer.readableBytes) ?? []
    }

    public init<Bytes: Sequence>(bytes: Bytes) throws(SolanaTransactionCodingError)
    where Bytes.Element == UInt8 {
        var buffer = SolanaTransactionBuffer(bytes: bytes)
        signatures = try [Signature].init(fromSolanaTransaction: &buffer)
        message = try CompiledVersionedMessage(fromSolanaTransaction: &buffer)
    }
}
