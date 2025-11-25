import Foundation
import Base58
import Base64
import SolanaTransactions
import SwiftBorsh

public struct TransactionOptions: Encodable, Equatable {
    public let encoding: TransactionEncoding?
    public let skipPreflight: Bool?
    public let preflightCommitment: Commitment?
    public let maxRetries: Int?
    public let minContextSlot: Int?

    public init(
        encoding: TransactionEncoding? = nil, skipPreflight: Bool? = nil,
        preflightCommitment: Commitment? = nil, maxRetries: Int? = nil, minContextSlot: Int? = nil
    ) {
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
    public func sendTransaction(
        transaction: Transaction,
        options: TransactionOptions? = nil
    ) async throws -> Signature {
        var params: [Encodable] = []

        let serializedTransaction = try transaction.encode()
        let encodedTransaction: String
        switch options?.encoding ?? .base58 {
        case .base58:
            encodedTransaction = serializedTransaction.base58EncodedString()
        case .base64:
            encodedTransaction = serializedTransaction.base64EncodedString()
        }
        params.append(encodedTransaction)

        if let options = options {
            params.append(options)
        }

        return try await fetch(
            method: "sendTransaction",
            params: params,
            into: Signature.self
        )
    }
}
