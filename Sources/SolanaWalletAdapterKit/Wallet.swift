import Foundation
import SolanaRPC
import SolanaTransactions

@MainActor
public protocol Wallet {
    init(for: AppIdentity, cluster: Endpoint, restoreFrom: SecureStorage) async throws

    var appId: AppIdentity { get set }
    var cluster: Endpoint { get set }
    var secureStorage: SecureStorage { get set }

    mutating func pair()
        async throws
    mutating func unpair()
        async throws

    nonmutating func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions?)
        async throws -> SignAndSendTransactionResponseData
    nonmutating func signAllTransactions(transactions: [Transaction])
        async throws -> SignAllTransactionsResponseData
    nonmutating func signTransaction(transaction: Transaction)
        async throws -> SignTransactionResponseData
    nonmutating func signMessage(message: Data, display: DisplayFormat?)
        async throws -> SignMessageResponseData

    nonmutating func browse(url: URL, ref: URL) async throws
}

public struct AppIdentity: Sendable {
    let name: String
    let url: URL
    let icon: String

    public init(name: String, url: URL, icon: String) {
        self.name = name
        self.url = url
        self.icon = icon
    }
}
