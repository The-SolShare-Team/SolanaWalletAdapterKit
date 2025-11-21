import Foundation
import SolanaRPC
import SolanaTransactions

public protocol WalletConnection: Codable {}

public protocol Wallet: SendableMetatype {
    associatedtype Connection: WalletConnection

    static var identifier: String { get }

    init(for: AppIdentity, cluster: Endpoint, connection: Connection?)

    var appId: AppIdentity { get }
    var cluster: Endpoint { get }

    var publicKey: PublicKey? { get }
    var isConnected: Bool { get }

    mutating func connect() async throws -> Connection?
    mutating func disconnect() async throws

    nonmutating func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions?)
        async throws -> SignAndSendTransactionResponseData
    nonmutating func signAllTransactions(transactions: [Transaction])
        async throws -> SignAllTransactionsResponseData
    nonmutating func signTransaction(transaction: Transaction)
        async throws -> SignTransactionResponseData
    nonmutating func signMessage(message: Data, display: MessageDisplayFormat?)
        async throws -> SignMessageResponseData

    nonmutating func browse(url: URL, ref: URL) async throws
}

extension Wallet {
    init(for appIdentity: AppIdentity, cluster: Endpoint) {
        self.init(for: appIdentity, cluster: cluster, connection: nil)
    }

    public var isConnected: Bool {
        return publicKey != nil
    }
}

public struct AppIdentity: Sendable, Hashable, Codable {
    let name: String
    let url: URL
    let icon: String

    public init(name: String, url: URL, icon: String) {
        self.name = name
        self.url = url
        self.icon = icon
    }
}
