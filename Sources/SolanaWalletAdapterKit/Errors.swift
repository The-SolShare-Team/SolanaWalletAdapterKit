import Foundation

/// Represents errors that can occur when interacting with Solana wallets through
/// the Wallet Adapter SDK.
///
/// Library errors cover misuses of the SDK or unexpected states, such as attempting
/// to connect to a wallet that is already connected or sending an invalid request.
///
/// Wallet errors correspond to error responses returned by the wallet application
/// over the deeplink protocol.
/// 
/// See:
/// - Solflare Errors: [https://docs.solflare.com/solflare/technical/deeplinks/limitations#errors](https://docs.solflare.com/solflare/technical/deeplinks/limitations#errors)
/// - Backpack Errors: [https://docs.backpack.app/deeplinks/limitations#errors](https://docs.backpack.app/deeplinks/limitations#errors)
/// - Phantom Errors: [https://docs.phantom.com/solana/errors](https://docs.phantom.com/solana/errors)
public enum SolanaWalletAdapterError: Error {
    // Library errors
    case alreadyConnected
    case notConnected
    case invalidRequest
    case invalidResponseFormat(response: [String: String])
    case browsingFailure

    // Errors wallets may return in a deeplink response.
    // - Solflare: https://docs.solflare.com/solflare/technical/deeplinks/limitations#errors
    // - Backpack: https://docs.backpack.app/deeplinks/limitations#errors
    // - Phantom: https://docs.phantom.com/solana/errors
    case disconnected(message: String)
    case unauthorized(message: String)
    case userRejectedRequest(message: String)
    case invalidInput(message: String)
    case resourceNotAvailable(message: String)
    case transactionRejected(message: String)
    case methodNotFound(message: String)
    case internalError(message: String)
    case unknownError(code: Int, message: String)

    init(walletErrorCode code: Int, message: String) {
        switch code {
        case 4900: self = .disconnected(message: message)
        case 4100: self = .unauthorized(message: message)
        case 4001: self = .userRejectedRequest(message: message)
        case -32000: self = .invalidInput(message: message)
        case -32002: self = .resourceNotAvailable(message: message)
        case -32003: self = .transactionRejected(message: message)
        case -32601: self = .methodNotFound(message: message)
        case -32603: self = .internalError(message: message)
        default: self = .unknownError(code: code, message: message)
        }
    }
}
