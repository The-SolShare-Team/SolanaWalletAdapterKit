import Base58
import SolanaTransactions
import SwiftBorsh
import Foundation

extension SolanaRPCClient {
    public struct SendTransactionConfiguration: Encodable {
        let encoding: TransactionEncoding?
        let skipPreflight: Bool?
        let preflightCommitment: Commitment?
        let maxRetries: Int?
        let minContextSlot: Int?

        public init(
            encoding: TransactionEncoding? = nil,
            skipPreflight: Bool? = nil,
            preflightCommitment: Commitment? = nil,
            maxRetries: Int? = nil,
            minContextSlot: Int? = nil
        ) {
            self.encoding = encoding
            self.skipPreflight = skipPreflight
            self.preflightCommitment = preflightCommitment
            self.maxRetries = maxRetries
            self.minContextSlot = minContextSlot
        }
    }

    public enum TransactionEncoding: String, Encodable {
        case base58
        case base64
    }

    /// https://solana.com/docs/rpc/http/sendtransaction
    public func sendTransaction(
        transaction: Transaction,
        configuration: SendTransactionConfiguration? = nil
    ) async throws -> Signature {
        let serializedTransaction = try transaction.encode()
        let encodedTransaction =
            switch configuration?.encoding ?? .base58 {
            case .base58: serializedTransaction.base58EncodedString()
            case .base64: serializedTransaction.base64EncodedString()
            }

        var params: [Encodable] = [encodedTransaction]
        if let configuration {
            params.append(configuration)
        }
        return try await fetch(
            method: "sendTransaction",
            params: params,
            into: Signature.self
        )
    }
}
