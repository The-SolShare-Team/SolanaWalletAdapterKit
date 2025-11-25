import Base58
import Base64
import SolanaTransactions
import SwiftBorsh

private struct RequestConfiguration: Encodable {
    let encoding: TransactionEncoding?
    let skipPreflight: Bool?
    let preflightCommitment: Commitment?
    let maxRetries: Int?
    let minContextSlot: Int?
}

public enum TransactionEncoding: String, Codable {
    case base58
    case base64
}

extension SolanaRPCClient {
    /// https://solana.com/docs/rpc/http/sendtransaction
    public func sendTransaction(
        transaction: Transaction,
        configuration: (
            encoding: TransactionEncoding?,
            skipPreflight: Bool?,
            preflightCommitment: Commitment?,
            maxRetries: Int?,
            minContextSlot: Int?,
        )? = nil
    ) async throws -> Signature {
        let serializedTransaction = try transaction.encode()
        let encodedTransaction =
            switch configuration?.encoding ?? .base58 {
            case .base58: serializedTransaction.base58EncodedString()
            case .base64: serializedTransaction.base64EncodedString()
            }

        var params: [Encodable] = [encodedTransaction]
        if let configuration {
            params.append(
                RequestConfiguration(
                    encoding: configuration.encoding,
                    skipPreflight: configuration.skipPreflight,
                    preflightCommitment: configuration.preflightCommitment,
                    maxRetries: configuration.maxRetries,
                    minContextSlot: configuration.minContextSlot
                )
            )
        }

        return try await fetch(
            method: "sendTransaction",
            params: params,
            into: Signature.self
        )
    }
}
