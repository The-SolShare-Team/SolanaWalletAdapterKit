import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC
import SolanaTransactions

public struct SolflareWallet: Wallet {
    public static let identifier = "solflare_wallet"

    public static let baseURL: URL = URL(string: "")!

    public typealias Connection = DeeplinkWalletConnection

    public let appId: AppIdentity
    public let cluster: Endpoint

    public var connection: DeeplinkWalletConnection?

    public var publicKey: PublicKey? { connection?.walletPublicKey }

    public init(
        for appId: AppIdentity, cluster: Endpoint, connection: Connection?
    ) {
        self.appId = appId
        self.cluster = cluster
        self.connection = connection
    }

    public mutating func pair() async throws -> Connection? {
        connection = try await DeeplinkWalletHelper.pair(
            baseURL: Self.baseURL, appId: appId, connection: connection)
        return connection
    }

    public mutating func unpair() async throws -> Connection? {

    }

    public func signAndSendTransaction(
        transaction: SolanaTransactions.Transaction, sendOptions: SendOptions?
    ) async throws -> SignAndSendTransactionResponseData {

    }

    public func signAllTransactions(transactions: [SolanaTransactions.Transaction]) async throws
        -> SignAllTransactionsResponseData
    {

    }

    public func signTransaction(transaction: SolanaTransactions.Transaction) async throws
        -> SignTransactionResponseData
    {

    }

    public func signMessage(message: Data, display: MessageDisplayFormat?) async throws
        -> SignMessageResponseData
    {

    }

    public func browse(url: URL, ref: URL) async throws {

    }

    // public static var baseURL: URL = URL(string: "https://solflare.com/ul/v1")!
    // public var connection: WalletConnection?
    // public var appId: AppIdentity
    // public var cluster: SolanaRPC.Endpoint
    // public var secureStorage: SecureStorage

    // public required init(
    //     for appId: AppIdentity,
    //     cluster: SolanaRPC.Endpoint,
    //     restoreFrom secureStorage: SecureStorage
    // ) async throws {
    //     self.appId = appId
    //     self.cluster = cluster
    //     self.secureStorage = secureStorage
    //     self.connection = try await secureStorage.retrieveWalletConnection(
    //         key: self.secureStorageKey)
    // }

    // public func pair() async throws {
    //     try await DeeplinkWalletHelper.pair(walletEncryptionPublicKeyIdentifier: "solflare_encryption_public_key")
    // }
}
