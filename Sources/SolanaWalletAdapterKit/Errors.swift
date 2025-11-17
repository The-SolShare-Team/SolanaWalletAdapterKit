import Foundation

public enum SolanaWalletAdapterError: Error {
    case alreadyConnected
    case notConnected
    case invalidResponse
    case pairingFailed
    case unpairingFailed
    case transactionSigningFailed
    case messageSigningFailed
    case browsingFailed
}

/// Errors wallets may return in a deeplink response.
/// Each error has a code and message.
/// - Solflare: https://docs.solflare.com/solflare/technical/deeplinks/limitations#errors
/// - Backpack: https://docs.backpack.app/deeplinks/limitations#errors
/// - Phantom: https://docs.phantom.com/solana/errors
enum WalletError: Error {
    case disconnected(message: String)
    case unauthorized(message: String)
    case userRejectedRequest(message: String)
    case invalidInput(message: String)
    case resourceNotAvailable(message: String)
    case transactionRejected(message: String)
    case methodNotFound(message: String)
    case internalError(message: String)
    case unknownError(code: Int, message: String)

    init(code: Int, message: String) {
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
