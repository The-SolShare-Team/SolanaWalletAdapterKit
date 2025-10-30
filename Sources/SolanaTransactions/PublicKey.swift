import Base58
import ByteBuffer

public struct PublicKey: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    // InlineArray is not widely enough supported to be used here
    public static let byteLength = 32
    public let bytes: [UInt8]

    public init?(bytes: [UInt8]) {
        if bytes.count != Self.byteLength { return nil }
        self.bytes = bytes
    }

    public init?(base58EncodedString string: String) {
        guard let decoded = try? Base58.decode(string) else { return nil }
        self.init(bytes: decoded)
    }

    public var description: String {
        Base58.encode(bytes)
    }

    public var debugDescription: String {
        "\(String(reflecting: Self.self))(base58EncodedString: \"\(Base58.encode(bytes))\"))"
    }
}

extension PublicKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        self.init(base58EncodedString: "\(value)")!
    }
}

extension PublicKey: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = UInt8

    public init(arrayLiteral elements: UInt8...) {
        self.init(bytes: elements)!
    }
}

extension PublicKey: SolanaTransactionCodable {
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
