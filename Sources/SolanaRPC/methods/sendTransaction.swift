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
            case .base58: Base58.encode(serializedTransaction)
            case .base64: Base64.encode(serializedTransaction)
            }

        return try await fetch(
            method: "sendTransaction",
            params: [
                encodedTransaction,
                configuration.map {
                    RequestConfiguration(
                        encoding: $0.encoding,
                        skipPreflight: $0.skipPreflight,
                        preflightCommitment: $0.preflightCommitment,
                        maxRetries: $0.maxRetries,
                        minContextSlot: $0.minContextSlot
                    )
                },
            ],
            into: Signature.self
        )
    }
}
