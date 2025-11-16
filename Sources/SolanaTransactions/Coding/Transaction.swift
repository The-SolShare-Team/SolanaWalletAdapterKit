import Foundation

public struct Transaction: Equatable {
    public let signatures: [Signature]
    public let message: VersionedMessage
}

extension Transaction {
    public func encode() throws(SolanaTransactionCodingError) -> Data {
        var buffer = SolanaTransactionBuffer()
        try signatures.solanaTransactionEncode(to: &buffer)
        try message.solanaTransactionEncode(to: &buffer)
        return Data(buffer.readBytes(length: buffer.readableBytes) ?? [])
    }

    public init<Bytes: Sequence>(bytes: Bytes) throws(SolanaTransactionCodingError)
    where Bytes.Element == UInt8 {
        var buffer = SolanaTransactionBuffer(bytes: bytes)
        signatures = try [Signature].init(fromSolanaTransaction: &buffer)
        message = try VersionedMessage(fromSolanaTransaction: &buffer)
    }
}
