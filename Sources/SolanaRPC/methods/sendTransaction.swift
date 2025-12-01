import Base58
import SolanaTransactions
import SwiftBorsh

extension SolanaRPCClient {
    /// Configuration options for the ``sendTransaction(transaction:configuration:)``  RPC request.
    ///  
    /// This struct allows you to provide **optional parameters** sending a transaction on the Solana blockchain. All properties are optional, so you can specify only the values you need.
    ///
    /// ```
    /// public init(
    ///     encoding: TransactionEncoding? = nil,
    ///     skipPreflight: Bool? = nil,
    ///     preflightCommitment: Commitment? = nil,
    ///     maxRetries: Int? = nil,
    ///     minContextSlot: Int? = nil
    /// ) {
    /// ```
    ///
    /// - Parameters:
    ///   - encoding: The format to use when serializing the transaction
    ///   - skipPreflight: Set to true to bypass the RPC node’s preflight checks
    ///   - preflightCommitment: The commitment level the node should use when running preflight. See ``Commitment``
    ///   - maxRetries: How many times the RPC node should attempt to forward the transaction to a leader. If omitted, the node continues retrying until the transaction is finalized or the blockhash expires.
    ///   - minContextSlot: The lowest slot at which preflight checks are allowed to run
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

    /// See [sendTransaction](https://solana.com/docs/rpc/http/sendtransaction) on Solana documentation for more details.
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
