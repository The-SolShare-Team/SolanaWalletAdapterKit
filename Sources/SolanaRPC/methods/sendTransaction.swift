import Base58
import SolanaTransactions
import SwiftBorsh
import Foundation

public struct TransactionOptions: Encodable, Equatable {
    public var encoding: TransactionEncoding?
    public var skipPreflight: Bool?
    public var preflightCommitment: Commitment?
    public var maxRetries: Int?
    public var minContextSlot: Int?

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
        let encodedTransaction =
            switch options?.encoding ?? .base58 {
            case .base58: Data(serializedTransaction).base58EncodedString()
            case .base64: Data(serializedTransaction).base64EncodedString()
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
