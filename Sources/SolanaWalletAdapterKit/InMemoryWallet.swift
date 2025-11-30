import CryptoKit
import Foundation
import SolanaRPC
import SolanaTransactions

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

public class InMemoryWallet: Wallet {
    public struct Connection: WalletConnection {
        public let privateKey: Curve25519.Signing.PrivateKey
        public let publicKey: PublicKey

        public init(privateKey: Curve25519.Signing.PrivateKey = Curve25519.Signing.PrivateKey()) {
            self.privateKey = privateKey
            self.publicKey = PublicKey(bytes: privateKey.publicKey.rawRepresentation)!
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let privateKeyData = try container.decode(Data.self)
            self.init(privateKey: try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData))
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(privateKey.rawRepresentation)
        }
    }

    public static let identifier = "in_memory_wallet"

    public let appId: AppIdentity
    public let cluster: Endpoint

    private let rpcClient: SolanaRPCClient

    var connection: Connection?

    public var publicKey: PublicKey? {
        return connection?.publicKey
    }

    public required init(for appIdentity: AppIdentity, cluster: Endpoint, connection: Connection?) {
        self.appId = appIdentity
        self.cluster = cluster
        self.connection = connection
        self.rpcClient = SolanaRPCClient(endpoint: cluster)
    }

    @discardableResult
    public func connect() throws -> Connection? {
        guard connection == nil else { throw SolanaWalletAdapterError.alreadyConnected }
        self.connection = Connection()
        return connection
    }

    public func disconnect() throws {
        guard connection != nil else { throw SolanaWalletAdapterError.notConnected }
        self.connection = nil
    }

    public func signMessage(message: Data, display: MessageDisplayFormat?) throws -> SignMessageResponseData {
        guard let connection = self.connection else { throw SolanaWalletAdapterError.notConnected }
        let signature = try connection.privateKey.signature(for: message)
        return SignMessageResponseData(signature: Signature(bytes: signature)!)
    }

    public func signTransaction(transaction: Transaction) throws -> SignTransactionResponseData {
        guard let connection = self.connection else { throw SolanaWalletAdapterError.notConnected }

        let data = try transaction.message.encode()

        guard
            let idx =
                switch transaction.message {
                case .legacyMessage(let message): message.accounts.prefix(Int(message.signatureCount)).firstIndex(of: connection.publicKey)
                case .v0(let message): message.accounts.prefix(Int(message.signatureCount)).firstIndex(of: connection.publicKey)
                }
        else {
            throw SolanaWalletAdapterError.transactionRejected(message: "\(connection.publicKey) is not a signer of the transaction")
        }

        let signature = try signMessage(message: data, display: nil).signature

        let signedTransaction = Transaction(
            signatures: transaction.signatures.enumerated().map { $0 == idx ? signature : $1 },
            message: transaction.message)

        return SignTransactionResponseData(transaction: signedTransaction)
    }

    public func signAllTransactions(transactions: [Transaction]) async throws -> SignAllTransactionsResponseData {
        let signedTransactions = try transactions.map { try signTransaction(transaction: $0).transaction }
        return SignAllTransactionsResponseData(transactions: signedTransactions)
    }

    public func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions?) async throws -> SignAndSendTransactionResponseData {
        let signedTransaction = try signTransaction(transaction: transaction).transaction

        let signature = try await rpcClient.sendTransaction(
            transaction: signedTransaction,
            configuration: SolanaRPCClient.SendTransactionConfiguration(
                encoding: .base58,
                skipPreflight: sendOptions?.skipPreflight,
                preflightCommitment: sendOptions?.preflightCommitment,
                maxRetries: sendOptions?.maxRetries,
                minContextSlot: sendOptions?.minContextSlot
            )
        )
        return SignAndSendTransactionResponseData(signature: signature)
    }

    @MainActor
    public func browse(url: URL, ref: URL) async throws {
        let finalURL = {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            var queryItems = components?.queryItems ?? []
            queryItems.append(URLQueryItem(name: "ref", value: ref.absoluteString))
            components?.queryItems = queryItems
            return components?.url ?? url
        }()

        #if os(iOS)
            let success = await UIApplication.shared.open(finalURL)
        #elseif os(macOS)
            let success = NSWorkspace.shared.open(finalURL)
        #endif

        if !success { throw SolanaWalletAdapterError.browsingFailure }
    }

    public static func isProbablyAvailable() -> Bool {
        return true
    }
}
