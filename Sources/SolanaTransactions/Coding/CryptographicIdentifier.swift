import Base58
import ByteBuffer
import Foundation
import SwiftBorsh

protocol CryptographicIdentifier: ExpressibleByArrayLiteral, ExpressibleByStringLiteral,
    SolanaTransactionCodable, Hashable, Sendable, CustomStringConvertible, BorshCodable, Codable
{
    static var byteLength: Int { get }
    var bytes: Data { get }
    init(bytes: Data)
}

extension CryptographicIdentifier {
    public init?(bytes: Data) {
        if bytes.count != Self.byteLength { return nil }
        self.init(bytes: bytes)
    }

    public init(arrayLiteral elements: UInt8...) {
        precondition(elements.count == Self.byteLength)
        self.init(bytes: Data(elements))
    }

    public init(stringLiteral value: StaticString) {
        let bytes = Data(base58Encoded: "\(value)")
        precondition(bytes != nil)
        precondition(bytes!.count == Self.byteLength)
        self.init(bytes: bytes!)
    }

    public var description: String {
        bytes.base58EncodedString()
    }

    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        guard let bytes = buffer.readBytes(length: Self.byteLength) else { throw .endOfBuffer }
        self.init(bytes: Data(bytes))
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        buffer.writeBytes(bytes)
    }

    public init(fromBorshBuffer buffer: inout BorshByteBuffer) throws(BorshDecodingError) {
        guard let bytes = buffer.readBytes(length: Self.byteLength) else { throw .endOfBuffer }
        self.init(bytes: Data(bytes))
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
        guard let bytes = Data(base58Encoded: string) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid Base58 public key: \(string)")
        }
        self.init(bytes: bytes)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }
}

extension PublicKey {
    public init(_ string: String) throws {
        let bytes = Base58.decode(string)
        precondition(bytes != nil)
        precondition(bytes!.count == Self.byteLength)
        self.init(bytes: bytes!)
    }
}
