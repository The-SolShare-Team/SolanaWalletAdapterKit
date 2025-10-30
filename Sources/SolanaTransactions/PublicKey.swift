import Base58
import ByteBuffer

public struct PublicKey: Equatable, CustomStringConvertible {
    let backing: (UInt64, UInt64, UInt64, UInt64)

    public init(base58: String) throws {
        let bytes = try Base58.decode(base58)
        var buffer = ByteBuffer(bytes: bytes)
        try self.init(fromSolanaTransaction: &buffer)
    }

    public static func == (lhs: PublicKey, rhs: PublicKey) -> Bool {
        return lhs.backing == rhs.backing
    }

    public var description: String {
        Base58.encode(bytes)
    }

    var bytes: [UInt8] {
        var bytes: [UInt8] = []
        withUnsafeBytes(of: backing.0.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.1.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.2.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.3.bigEndian) { bytes.append(contentsOf: $0) }
        return bytes
    }
}

extension PublicKey: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        try! self.init(base58: "\(value)")
    }
}

extension PublicKey: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        guard let data: (UInt64, UInt64, UInt64, UInt64) = buffer.readMultipleIntegers() else {
            throw .endOfBuffer
        }
        self.backing = data
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        buffer.writeMultipleIntegers(backing.0, backing.1, backing.2, backing.3)
    }
}
