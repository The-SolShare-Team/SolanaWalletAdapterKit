import Base58
import ByteBuffer
import Foundation
import SwiftBorsh

/// A protocol representing a fixed-length cryptographic identifier such as
/// a Solana public key or signature.
///
/// Conforming types must define:
///  - ``byteLength``: the fixed byte size of the identifier
///  - ``bytes``: the underlying raw bytes
public protocol CryptographicIdentifier: ExpressibleByArrayLiteral, ExpressibleByStringLiteral,
    Sendable, CustomStringConvertible, BorshCodable, Codable, Equatable, Hashable, Comparable
{
    /// The required byte length for this identifier.
    static var byteLength: Int { get }

    /// The raw bytes that represent this identifier.
    var bytes: Data { get }

    /// Creates an identifier from a raw byte collection.
    ///
    /// Returns `nil` if the byte count does not match ``byteLength``.
    init?<Bytes: Collection>(bytes: Bytes) where Bytes.Element == UInt8

    /// Creates an identifier from a Base58-encoded string.
    ///
    /// Returns `nil` if the string is not valid Base58 or does not decode
    /// to the expected ``byteLength``.
    init?(string: String)
}

protocol _CryptographicIdentifier: SolanaTransactionCodable, CryptographicIdentifier {
    /// Internal initializer exposed to allow construction once the byte
    /// count is validated.
    init(bytes: Data)
}

extension CryptographicIdentifier {

    /// Creates an identifier from a Base58 string.
    ///
    /// Returns `nil` if decoding fails or if the resulting bytes do not match
    /// this type’s ``byteLength``.
    public init?(string: String) {
        guard let bytes = Data(base58Encoded: string) else { return nil }
        self.init(bytes: bytes)
    }

    /// A Base58 string representation of the identifier.
    public var description: String {
        bytes.base58EncodedString()
    }

    /// Decodes this identifier from a Borsh buffer.
    ///
    /// - Throws: ``BorshDecodingError`` if the buffer does not contain
    ///   the required number of bytes or the value is invalid.
    public init(fromBorshBuffer buffer: inout BorshByteBuffer) throws(BorshDecodingError) {
        guard let bytes = buffer.readBytes(length: Self.byteLength) else { throw .endOfBuffer }
        guard let result = Self(bytes: Data(bytes)) else {
            throw BorshDecodingError.invalidValue
        }
        self = result
    }

    /// Encodes this identifier into a Borsh buffer.
    ///
    /// - Throws: ``BorshEncodingError`` if writing fails.
    public func borshEncode(to buffer: inout BorshByteBuffer) throws(BorshEncodingError) {
        buffer.writeBytes(bytes)
    }

    /// Encodes this identifier into a Base58 string for use with Codable.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    /// Decodes this identifier from a Base58 string using Codable.
    ///
    /// - Throws: ``DecodingError`` if the string is invalid or not the
    ///   correct length for this identifier type.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let bytes = Data(base58Encoded: string) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid Base58 string: \(string)")
        }
        guard let result = Self(bytes: bytes) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid \(Self.self): \(bytes)")
        }
        self = result
    }

    /// Hashes this identifier by hashing its raw bytes.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytes)
    }

    /// Identifiers are equal if their raw bytes match.
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
        precondition(elements.count == Self.byteLength,
            "Invalid \(Self.self) array literal: \(elements)")
        self.init(bytes: Data(elements))
    }

    public init(stringLiteral value: StaticString) {
        let bytes = Data(base58Encoded: "\(value)")
        precondition(bytes != nil && bytes!.count == Self.byteLength,
            "Invalid \(Self.self) string literal: \(value)")
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
