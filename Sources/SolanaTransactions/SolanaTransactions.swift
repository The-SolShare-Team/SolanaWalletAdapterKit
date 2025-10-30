import ByteBuffer
import Foundation

typealias SolanaTransactionBuffer = ByteBuffer

public typealias Blockhash = PublicKey

public struct Transaction: Equatable {
    let signatures: [Signature]
    let message: VersionedMessage
}

extension Transaction: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        signatures = try [Signature].init(fromSolanaTransaction: &buffer)
        message = try VersionedMessage(fromSolanaTransaction: &buffer)
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        try signatures.solanaTransactionEncode(to: &buffer)
        try message.solanaTransactionEncode(to: &buffer)
    }
}
