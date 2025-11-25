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



// Assuming these types are defined in your project
public enum Commitment: String, Codable {
    case processed, confirmed, finalized
}

public enum TransactionEncoding: String, Codable {
    case base58, base64
}

public struct SendOptions: Codable {
    public let maxRetries: Int?
    public let minContextSlot: Int?
    public let preflightCommitment: Commitment?
    public let skipPreflight: Bool?
    
    // Add an initializer for easier testing/creation
    public init(maxRetries: Int? = nil, minContextSlot: Int? = nil, preflightCommitment: Commitment? = nil, skipPreflight: Bool? = nil) {
        self.maxRetries = maxRetries
        self.minContextSlot = minContextSlot
        self.preflightCommitment = preflightCommitment
        self.skipPreflight = skipPreflight
    }
}

private struct RequestConfiguration: Encodable {
    let encoding: TransactionEncoding?
    let skipPreflight: Bool?
    let preflightCommitment: Commitment?
    let maxRetries: Int?
    let minContextSlot: Int?
}


// --- SOLUTION ---

extension RequestConfiguration {
    /// Creates a `RequestConfiguration` by unwrapping properties from `SendOptions`
    /// and a separate `encoding` value.
    /// - Parameters:
    ///   - sendOptions: The options containing request-specific settings.
    ///   - encoding: The desired transaction encoding.
    init(sendOptions: SendOptions, encoding: TransactionEncoding?) {
        // Leverage the memberwise initializer for clarity and conciseness.
        self.init(
            encoding: encoding,
            skipPreflight: sendOptions.skipPreflight,
            preflightCommitment: sendOptions.preflightCommitment,
            maxRetries: sendOptions.maxRetries,
            minContextSlot: sendOptions.minContextSlot
        )
    }
}

// --- USAGE ---

let options = SendOptions(skipPreflight: true, preflightCommitment: .finalized)
let encoding = TransactionEncoding.base64

// 1. Create the tuple
let inputs = (options, encoding)

// 2. Unwrap cleanly using the new initializer
let config = RequestConfiguration(sendOptions: inputs.0, encoding: inputs.1)

// You can also destructure the tuple first for readability
let (sendOpts, txEncoding) = inputs
let config2 = RequestConfiguration(sendOptions: sendOpts, encoding: txEncoding)

print(config)
