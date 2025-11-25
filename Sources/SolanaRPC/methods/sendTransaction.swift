import Base58
import SolanaTransactions
import SwiftBorsh

public struct TransactionOptions: Encodable, Equatable {
    public var encoding: TransactionEncoding?
    public var skipPreflight: Bool?
    public var preflightCommitment: Commitment?
    public var maxRetries: Int?
    public var minContextSlot: Int?
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

        return try await fetch(
            method: "sendTransaction",
            params: [
                encodedTransaction,
                configuration.map {
                    TransactionOptions(
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
    
    public func sendTransaction(
        transaction: Transaction,
        transactionOptions: TransactionOptions
    ) async throws -> Signature {
        // Convert the struct to a tuple and call the original function
        let tupleConfig =
        (
            encoding: transactionOptions.encoding,
            skipPreflight: transactionOptions.skipPreflight,
            preflightCommitment: transactionOptions.preflightCommitment,
            maxRetries: transactionOptions.maxRetries,
            minContextSlot: transactionOptions.minContextSlot
        )

        return try await self.sendTransaction(
            transaction: transaction,
            configuration: tupleConfig
        )
    }
}
