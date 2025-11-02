import Base58
import ByteBuffer
import SwiftBorsh

protocol CryptographicIdentifier: ExpressibleByArrayLiteral, ExpressibleByStringLiteral,
    SolanaTransactionCodable, Hashable, Sendable, CustomStringConvertible, BorshCodable, Codable
{
    static var byteLength: Int { get }
    var bytes: [UInt8] { get }
    init(bytes: [UInt8])
}

extension CryptographicIdentifier {
    public init?(bytes: [UInt8]) {
        if bytes.count != Self.byteLength { return nil }
        self.init(bytes: bytes)
    }

    public init(arrayLiteral elements: UInt8...) {
        precondition(elements.count == Self.byteLength)
        self.init(bytes: elements)
    }

    public init(stringLiteral value: StaticString) {
        let bytes = Base58.decode("\(value)")
        precondition(bytes != nil)
        precondition(bytes!.count == Self.byteLength)
        self.init(bytes: bytes!)
    }

    public var description: String {
        Base58.encode(bytes)
    }

    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        guard let bytes = buffer.readBytes(length: Self.byteLength) else { throw .endOfBuffer }
        self.init(bytes: bytes)
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        buffer.writeBytes(bytes)
    }

    public init(fromBorshBuffer buffer: inout BorshByteBuffer) throws(BorshDecodingError) {
        guard let bytes = buffer.readBytes(length: Self.byteLength) else { throw .endOfBuffer }
        self.init(bytes: bytes)
    }

    public func borshEncode(to buffer: inout BorshByteBuffer) throws(BorshEncodingError) {
        buffer.writeBytes(bytes)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let bytes = Base58.decode(string) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid Base58 public key: \(string)")
        }
        self.init(bytes: bytes)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }
}
