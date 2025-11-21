<<<<<<< HEAD:Sources/SolanaWalletAdapterKit/Wallets/Wallet.swift
import CryptoKit
public protocol Wallet {
    var isConnected: Bool { get set}
    var dappEncryptionPublicKey: Curve25519.KeyAgreement.PublicKey { get }
    var dappEncryptionSharedKey: SymmetricKey? { get set}
    mutating func connect(appUrl: String, redirectLink: String, cluster: String?) async throws
    func disconnect(nonce: String, redirectLink: String, payload: String) async throws
    
    func signAndSendTransaction(nonce: String, redirectLink: String, payload: String) async throws
    func signAllTransactions(nonce: String, redirectLink: String, payload: String) async throws
    func signTransaction(nonce: String, redirectLink: String, payload: String) async throws
    func signMessage(nonce: String, redirectLink: String, payload: String) async throws
    
    func browse(url: String, ref: String) async throws
=======
import Foundation
import SolanaRPC
import SolanaTransactions

@MainActor
public protocol Wallet {
    init(for: AppIdentity, cluster: Endpoint, restoreFrom: SecureStorage) async throws

    var appId: AppIdentity { get set }
    var cluster: Endpoint { get set }
    var secureStorage: SecureStorage { get set }
    var connection: WalletConnection? { get set }

    mutating func pair()
        async throws
    mutating func unpair(nonce: String, redirectLink: String, payload: String)
        async throws

    nonmutating func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions?)
        async throws -> SignAndSendTransactionResponse
    nonmutating func signAllTransactions(transactions: [Transaction])
        async throws -> SignAllTransactionsResponse
    nonmutating func signTransaction(transaction: Transaction)
        async throws -> SignTransactionResponse
    nonmutating func signMessage(message: Data, display: DisplayFormat?)
        async throws -> SignMessageResponse

    nonmutating func browse(url: URL, ref: URL) async throws
}

public struct WalletConnection: Codable {
    let encryption: DiffieHellmanData
    public var walletPublicKey: String
    public var session: String

    public init(encryption: DiffieHellmanData, walletPublicKey: String, session: String) {
        self.encryption = encryption
        self.walletPublicKey = walletPublicKey
        self.session = session
    }
}

public struct DiffieHellmanData: Codable {
    let publicKey: Data
    let privateKey: Data
    let sharedKey: Data

    public init(publicKey: Data, privateKey: Data, sharedKey: Data) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.sharedKey = sharedKey
    }
}

public struct ConnectResponse: Decodable {
    public let publicKey: String
    public let session: String

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case session
    }
}

public struct SignAndSendTransactionResponse: Decodable {
    public let signature: String
}

public struct SignAllTransactionsResponse: Decodable {
    public let transactions: [String]
}

public struct SignTransactionResponse: Decodable {
    public let transaction: String
}

public struct SignMessageResponse: Decodable {
    public let signature: String
}

// SendOptions type based on https://solana-foundation.github.io/solana-web3.js/types/SendOptions.html
public struct SendOptions: Codable {
    public let maxRetries: Int?
    public let minContextSlot: Int?
    public let preflightCommitment: Commitment?
    public let skipPreflight: Bool?
}

public enum DisplayFormat: String {
    case hex = "hex"
    case utf8 = "utf-8"
}


/// Error from the wallets:
/// - Solflare: https://docs.solflare.com/solflare/technical/deeplinks/limitations#errors
/// - Backpack: https://docs.backpack.app/deeplinks/limitations#errors
/// - Phantom: https://docs.phantom.com/solana/errors
enum WalletError: Error, LocalizedError {
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
