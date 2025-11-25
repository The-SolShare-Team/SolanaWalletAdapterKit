import Foundation
import SolanaRPC

// ***********************************
// Method Types
// ***********************************

struct DisconnectRequestPayload: Encodable, Sendable {
    let session: String
}

struct SignAndSendTransactionRequestPayload: Encodable, Sendable {
    let transaction: String
    let sendOptions: String?
    let session: String

    init(transaction: String, sendOptions: SendOptions?, session: String) throws {
        self.transaction = transaction
        self.session = session

        if let sendOptions {
            let json = try JSONEncoder().encode(sendOptions)
            self.sendOptions = String(data: json, encoding: .utf8)
        } else {
            self.sendOptions = nil
        }
    }
}

struct SignAllTransactionsRequestPayload: Encodable, Sendable {
    let transactions: [String]
    let session: String
}

struct SignTransactionRequestPayload: Encodable, Sendable {
    let transaction: String
    let session: String
}

struct SignMessageRequestPayload: Encodable, Sendable {
    let message: String
    let session: String
    let display: MessageDisplayFormat?
}

// ***********************************
// Helper types
// ***********************************

// SendOptions type based on https://solana-foundation.github.io/solana-web3.js/types/SendOptions.html
public struct SendOptions: Codable {
    public let maxRetries: Int?
    public let minContextSlot: Int?
    public let preflightCommitment: Commitment?
    public let skipPreflight: Bool?
}

public enum MessageDisplayFormat: String, Encodable, Sendable {
    case hex
    case utf8
}



extension TransactionOptions {
    public init(sendOptions: SendOptions? = nil, encoding: TransactionEncoding? = nil) {
        // 1. Create a temporary, default instance.
        var newOptions = TransactionOptions()
        // 2. Set the properties on the temporary instance.
        newOptions.encoding = encoding
        newOptions.skipPreflight = sendOptions?.skipPreflight
        newOptions.preflightCommitment = sendOptions?.preflightCommitment
        newOptions.maxRetries = sendOptions?.maxRetries
        newOptions.minContextSlot = sendOptions?.minContextSlot

        // 3. Assign the configured instance to self.
        self = newOptions
    }
}
