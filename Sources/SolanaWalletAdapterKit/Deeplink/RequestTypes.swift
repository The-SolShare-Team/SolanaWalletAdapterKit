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

/// Used to configure how a transaction is sent to the network via an RPC client
///
/// See ``SignAndSendTransactionResponseData`` to see how it is used.
///
/// SendOptions type based on [following docs](https://solana-foundation.github.io/solana-web3.js/types/SendOptions.html).
///
/// - Parameters:
///   - maxRetries: Maximum number of times for the RPC node to retry sending the transaction to the leader. If this parameter not provided, the RPC node will retry the transaction until it is finalized or until the blockhash expires.
///   - minContextSlot: Set the minimum slot at which to perform preflight transaction checks
///   - preflightCommitment: Commitment level to use for preflight. See ``Commitment``
///   - skipPreflight: Disable transaction verification step
public struct SendOptions: Codable {
    public let maxRetries: Int?
    public let minContextSlot: Int?
    public let preflightCommitment: Commitment?
    public let skipPreflight: Bool?
}

/// Specifies how a message should be displayed or interpreted.
///
/// ## Options:
///   - **hex**: Display the message as a hexadecimal string.
///   - **utf8**: Display the message as a UTF-8 string.
public enum MessageDisplayFormat: String, Encodable, Sendable {
    case hex
    case utf8
}
