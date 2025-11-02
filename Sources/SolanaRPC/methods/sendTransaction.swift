import SolanaTransactions
import SwiftBorsh

public struct TransactionOptions: Codable, Equatable {
    public let encoding: TransactionEncoding?
    public let skipPreflight: Bool?
    public let preflightCommitment: Commitment?
    public let maxRetries: UInt64?
    public let minContextSlot: Int?


    public init(
        skipPreflight: Bool? = nil,
        preflightCommitment: Commitment? = nil,
        encoding: TransactionEncoding? = nil,
        maxRetries: UInt64? = nil,
        minContextSlot: Int? = nil
    ) {
        self.skipPreflight = skipPreflight
        self.preflightCommitment = preflightCommitment
        self.encoding = encoding
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
    ) async throws {
        let serializedData = try transaction.encode()
        _ = try await fetch(
            method: "sendTransaction",
            params: [serializedData, options ?? TransactionOptions()],
            into: String.self
        )

    }
}
