import Foundation
import SolanaRPC
import SolanaTransactions

public protocol WalletConnection: Codable {
    var publicKey: PublicKey { get }
}

/// Represents a generic Solana wallet that can connect, sign transactions and messages, and interact with a dApp.
public protocol Wallet: SendableMetatype {
    associatedtype Connection: WalletConnection

    static var identifier: String { get }

    /// Initializes a wallet instance for a given application identity and Solana cluster.
    init(for: AppIdentity, cluster: Endpoint, connection: Connection?)

    var appId: AppIdentity { get }
    var cluster: Endpoint { get }

    var publicKey: PublicKey? { get }
    var isConnected: Bool { get }

    /// Connect to the wallet.
    @discardableResult
    mutating func connect() async throws -> Connection?

    /// Disconnect from the wallet.
    mutating func disconnect() async throws

    /// Sign and send a transaction using the wallet.
    nonmutating func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions?)
        async throws -> SignAndSendTransactionResponseData

    /// Sign all transactions using the wallet.
    nonmutating func signAllTransactions(transactions: [Transaction])
        async throws -> SignAllTransactionsResponseData

    /// Sign a transaction using the wallet.
    nonmutating func signTransaction(transaction: Transaction)
        async throws -> SignTransactionResponseData

    /// Sign a message using the wallet.
    nonmutating func signMessage(message: Data, display: MessageDisplayFormat?)
        async throws -> SignMessageResponseData

    /// Open a URL using the wallet's in-app browser.
    @MainActor
    nonmutating func browse(url: URL, ref: URL) async throws

    static func isProbablyAvailable() -> Bool
}

extension Wallet {
    init(for appIdentity: AppIdentity, cluster: Endpoint) {
        self.init(for: appIdentity, cluster: cluster, connection: nil)
    }

    public var isConnected: Bool {
        return publicKey != nil
    }
}

/// Represents the identity of a dApp requesting wallet access.
public struct AppIdentity: Sendable, Codable, Equatable {
    public let name: String
    public let url: URL
    public let icon: String

    /// Initializes a new dApp identity.
    ///
    /// - Parameters:
    ///   - name: The display name of the application.
    ///   - url: The base URL of the application.
    ///   - icon: The URL or resource name of the application’s icon.
    public init(name: String, url: URL, icon: String) {
        self.name = name
        self.url = url
        self.icon = icon
    }

    public static func == (lhs: AppIdentity, rhs: AppIdentity) -> Bool {
        return lhs.name == rhs.name && lhs.url == rhs.url
    }
}
