import ByteBuffer

public struct Signature: Equatable {
    // InlineArray is not widely enough supported to be used here
    public static let byteLength = 64
    public let bytes: [UInt8]

    public init?(bytes: [UInt8]) {
        if bytes.count != Self.byteLength { return nil }
        self.bytes = bytes
    }
}

extension Signature: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = UInt8

    public init(arrayLiteral elements: UInt8...) {
        self.init(bytes: elements)!
    }
}

extension Signature: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        guard let data = buffer.readBytes(length: Self.byteLength) else { throw .endOfBuffer }
        self.bytes = data
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        buffer.writeBytes(bytes)
    }
}
