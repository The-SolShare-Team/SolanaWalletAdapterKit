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
    ///   - encoding: Encoding used for the transaction data. Values: `.base58` (slow, DEPRECATED), or `.base64`.
    ///   - skipPreflight: When true, skip the preflight transaction checks.
    ///   - preflightCommitment: Commitment level to use for preflight. See ``Commitment``
    ///   - maxRetries: Maximum number of times for the RPC node to retry sending the transaction to the leader. If this parameter not provided, the RPC node will retry the transaction until it is finalized or until the blockhash expires.
    ///   - minContextSlot: Set the minimum slot at which to perform preflight transaction checks
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

    /// Submits a signed transaction to the cluster for processing.
    ///
    /// See [sendTransaction](https://solana.com/docs/rpc/http/sendtransaction) on Solana documentation for more details.
    /// - Parameters:
    ///   - transaction: Fully-signed Transaction, as encoded string. See ``TransactionEncoding``
    ///   - configuration: Optional configuration for the request. Defaults to `nil`. See ``SendTransactionConfiguration``
    ///
    /// - Returns: First Transaction Signature embedded in the transaction, as base-58 encoded string.
    ///
    /// - Throws: `RPCError` if the request fails or the response is invalid.
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
