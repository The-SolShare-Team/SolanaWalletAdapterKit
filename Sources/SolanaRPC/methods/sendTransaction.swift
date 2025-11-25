import Base58
import SolanaTransactions
import SwiftBorsh
public struct TransactionOptions: Encodable, Equatable {
    public var encoding: TransactionEncoding?
    public var skipPreflight: Bool?
    public var preflightCommitment: Commitment?
    public var maxRetries: Int?
    public var minContextSlot: Int?
    
    public init(encoding: TransactionEncoding? = nil, skipPreflight: Bool? = nil, preflightCommitment: Commitment? = nil, maxRetries: Int? = nil, minContextSlot: Int? = nil) {
        self.encoding = encoding
        self.skipPreflight = skipPreflight
        self.preflightCommitment = preflightCommitment
        self.maxRetries = maxRetries
        self.minContextSlot = minContextSlot
    }
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
        var params: [Encodable] = []
        params.append(encodedTransaction)
        if let config = configuration {
            params.append(
                TransactionOptions(
                    encoding: config.encoding,
                    skipPreflight: config.skipPreflight,
                    preflightCommitment: config.preflightCommitment,
                    maxRetries: config.maxRetries,
                    minContextSlot: config.minContextSlot
                )
            )
        }
        return try await fetch(
            method: "sendTransaction",
            params: params,
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
