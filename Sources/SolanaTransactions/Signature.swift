import ByteBuffer

public struct Signature: CustomDebugStringConvertible, Equatable {
    let backing: (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64)

    var bytes: [UInt8] {
        var bytes: [UInt8] = []
        withUnsafeBytes(of: backing.0.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.1.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.2.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.3.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.4.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.5.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.6.bigEndian) { bytes.append(contentsOf: $0) }
        withUnsafeBytes(of: backing.7.bigEndian) { bytes.append(contentsOf: $0) }
        return bytes
    }

    public var debugDescription: String {
        "\(String(reflecting: Self.self))(\(bytes))"
    }

    public static func == (lhs: Signature, rhs: Signature) -> Bool {
        return lhs.backing.0 == rhs.backing.0 && lhs.backing.1 == rhs.backing.1
            && lhs.backing.2 == rhs.backing.2 && lhs.backing.3 == rhs.backing.3
            && lhs.backing.4 == rhs.backing.4 && lhs.backing.5 == rhs.backing.5
            && lhs.backing.6 == rhs.backing.6 && lhs.backing.7 == rhs.backing.7
    }
}

extension Signature: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = UInt8

    public init(arrayLiteral elements: UInt8...) {
        var buffer = ByteBuffer(bytes: elements)
        try! self.init(fromSolanaTransaction: &buffer)
    }
}

extension Signature: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        guard
            let data: (UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64, UInt64) =
                buffer.readMultipleIntegers()
        else { throw .endOfBuffer }
        self.backing = data
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        buffer.writeMultipleIntegers(
            backing.0, backing.1, backing.2, backing.3, backing.4, backing.5, backing.6, backing.7)
    }
}
