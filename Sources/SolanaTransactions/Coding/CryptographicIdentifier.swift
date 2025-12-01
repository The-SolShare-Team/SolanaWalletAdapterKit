import Base58
import ByteBuffer
import Foundation
import SwiftBorsh

// This pair of protocols works in tandem to provide a clean public interface, whilst
// staying compatible with the Swift visibility rules. This, for example, allows
// to expose a safe public initializer, based on the automatically synthesized
// initializer of the consuming structs. Both protocols should be adopted by the
// consuming structs.

public protocol CryptographicIdentifier: ExpressibleByArrayLiteral, ExpressibleByStringLiteral,
    Sendable, CustomStringConvertible, BorshCodable, Codable, Equatable, Hashable, Comparable
{
    static var byteLength: Int { get }
    var bytes: Data { get }
    init?<Bytes: Collection>(bytes: Bytes) where Bytes.Element == UInt8
    init?(string: String)
}

protocol _CryptographicIdentifier: SolanaTransactionCodable, CryptographicIdentifier {
    init(bytes: Data)
}

extension CryptographicIdentifier {
    public init?(string: String) {
        guard let bytes = Data(base58Encoded: string) else { return nil }
        self.init(bytes: bytes)
    }

    public var description: String {
        bytes.base58EncodedString()
    }

    public init(fromBorshBuffer buffer: inout BorshByteBuffer) throws(BorshDecodingError) {
        guard let bytes = buffer.readBytes(length: Self.byteLength) else { throw .endOfBuffer }
        guard let result = Self(bytes: Data(bytes)) else {
            throw BorshDecodingError.invalidValue
        }
        self = result
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
                in: container, debugDescription: "Invalid Base58 string: \(string)")
        }
        guard let result = Self(bytes: bytes) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid \(Self.self): \(bytes)")
        }
        self = result
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.bytes == rhs.bytes
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.description.lexicographicallyPrecedes(rhs.description)
    }
}

extension _CryptographicIdentifier {
    public init?<Bytes: Collection>(bytes: Bytes) where Bytes.Element == UInt8 {
        if bytes.count != Self.byteLength { return nil }
        self.init(bytes: Data(bytes))
    }

    public init(arrayLiteral elements: UInt8...) {
        precondition(elements.count == Self.byteLength, "Invalid \(Self.self) array literal: \(elements)")
        self.init(bytes: Data(elements))
    }

    public init(stringLiteral value: StaticString) {
        let bytes = Data(base58Encoded: "\(value)")
        precondition(bytes != nil && bytes!.count == Self.byteLength, "Invalid \(Self.self) string literal: \(value)")
        self.init(bytes: bytes!)
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
}
