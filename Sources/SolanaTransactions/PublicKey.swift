import Base58
import ByteBuffer
import SwiftBorsh

public struct PublicKey {
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
}

extension PublicKey: Sendable {}

extension PublicKey: Hashable {}

extension PublicKey: Equatable {}

extension PublicKey: CustomStringConvertible {
    public var description: String {
        Base58.encode(bytes)
    }
}

extension PublicKey: CustomDebugStringConvertible {
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

extension PublicKey: BorshCodable {
    public func borshEncode(to buffer: inout SwiftBorsh.BorshByteBuffer) throws(SwiftBorsh
        .BorshEncodingError)
    {
        try bytes.borshEncode(to: &buffer)
    }

    public init(fromBorshBuffer buffer: inout SwiftBorsh.BorshByteBuffer) throws(SwiftBorsh
        .BorshDecodingError)
    {
        bytes = try [UInt8].init(fromBorshBuffer: &buffer)
    }
}
