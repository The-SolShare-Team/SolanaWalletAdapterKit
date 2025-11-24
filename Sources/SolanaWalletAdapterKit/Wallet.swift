import Foundation
import SolanaRPC
import SolanaTransactions

public protocol WalletConnection: Codable {
    var publicKey: PublicKey { get }
    var session: String {get }
}

public protocol Wallet: SendableMetatype {
    associatedtype Connection: WalletConnection
    
    static var identifier: String { get }
    
    init(for: AppIdentity, cluster: Endpoint, connection: Connection?)
    
    var appId: AppIdentity { get }
    var cluster: Endpoint { get }
    var connection: Connection? {get set}
    var publicKey: PublicKey? { get }
    var isConnected: Bool { get }

    /// Connect to the wallet.
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
    nonmutating func browse(url: URL, ref: URL) async throws

    static func isProbablyAvailable() -> Bool
}

extension Wallet {
    init(for appIdentity: AppIdentity, cluster: Endpoint) {
        self.init(for: appIdentity, cluster: cluster, connection: nil as Connection?)
    }

    public var isConnected: Bool {
        return publicKey != nil
    }
}

public struct AppIdentity: Sendable, Codable, Equatable {
    public let name: String
    public let url: URL
    public let icon: String

    public init(name: String, url: URL, icon: String) {
        self.name = name
        self.url = url
        self.icon = icon
    }
}
