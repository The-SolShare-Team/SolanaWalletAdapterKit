import CryptoKit
import Foundation
import SolanaRPC
import SolanaTransactions

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

/// An in-memory wallet implementation that stores keys locally and signs transactions
/// without interacting with an external wallet app.
///
/// This wallet is useful for testing, prototyping, or temporary usage where
/// a persistent wallet is not required.
///
/// **Note**: Since the keys are only stored in memory, all data will be lost
/// when the wallet instance is deinitialized.
public class InMemoryWallet: Wallet {
    public struct Connection: WalletConnection {
        public let privateKey: Curve25519.Signing.PrivateKey
        public let publicKey: PublicKey

        /// Initializes a new connection with a fresh private key.
        ///
        /// - Parameter privateKey: Optionally provide an existing private key.
        public init(privateKey: Curve25519.Signing.PrivateKey = Curve25519.Signing.PrivateKey()) {
            self.privateKey = privateKey
            self.publicKey = PublicKey(bytes: privateKey.publicKey.rawRepresentation)!
        }

        /// Initializes the connection from a decoder (e.g., for persistence).
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let privateKeyData = try container.decode(Data.self)
            self.init(privateKey: try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData))
        }

        /// Encodes the connection into a format suitable for storage.
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

    /// Initializes a new `InMemoryWallet` instance.
    ///
    /// - Parameters:
    ///   - appIdentity: The identity of the dApp using the wallet.
    ///   - cluster: The Solana network cluster.
    ///   - connection: An optional existing connection to restore a session.
    public required init(for appIdentity: AppIdentity, cluster: Endpoint, connection: Connection?) {
        self.appId = appIdentity
        self.cluster = cluster
        self.connection = connection
        self.rpcClient = SolanaRPCClient(endpoint: cluster)
    }

    /// Creates a new in-memory connection.
    ///
    /// - Throws: `SolanaWalletAdapterError.alreadyConnected` if already connected.
    /// - Returns: The newly created connection.
    @discardableResult
    public func connect() throws -> Connection? {
        guard connection == nil else { throw SolanaWalletAdapterError.alreadyConnected }
        self.connection = Connection()
        return connection
    }

    /// Creates a new in-memory connection.
    ///
    /// - Throws: `SolanaWalletAdapterError.alreadyConnected` if already connected.
    /// - Returns: The newly created connection.
    public func disconnect() throws {
        guard connection != nil else { throw SolanaWalletAdapterError.notConnected }
        self.connection = nil
    }

    /// Signs a message using the wallet's private key.
    ///
    /// - Parameters:
    ///   - message: The raw data to sign.
    ///   - display: Optional display format for the message.
    /// - Throws: `SolanaWalletAdapterError.notConnected` if wallet is disconnected.
    /// - Returns: A `SignMessageResponseData` containing the signature.
    public func signMessage(message: Data, display: MessageDisplayFormat?) throws -> SignMessageResponseData {
        guard let connection = self.connection else { throw SolanaWalletAdapterError.notConnected }
        let signature = try connection.privateKey.signature(for: message)
        return SignMessageResponseData(signature: Signature(bytes: signature)!)
    }

    /// Signs a message using the wallet's private key.
    ///
    /// - Parameters:
    ///   - message: The raw data to sign.
    ///   - display: Optional display format for the message.
    /// - Throws: `SolanaWalletAdapterError.notConnected` if wallet is disconnected.
    /// - Returns: A `SignMessageResponseData` containing the signature.
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

    /// Signs multiple transactions.
    ///
    /// - Parameter transactions: The transactions to sign.
    /// - Throws: Propagates errors from `signTransaction`.
    /// - Returns: A `SignAllTransactionsResponseData` containing all signed transactions.
    public func signAllTransactions(transactions: [Transaction]) async throws -> SignAllTransactionsResponseData {
        let signedTransactions = try transactions.map { try signTransaction(transaction: $0).transaction }
        return SignAllTransactionsResponseData(transactions: signedTransactions)
    }

    /// Signs and sends a transaction via the configured RPC client.
    ///
    /// - Parameters:
    ///   - transaction: The transaction to sign and send.
    ///   - sendOptions: Optional send options like preflight checks and retries.
    /// - Throws: Errors from signing or sending the transaction.
    /// - Returns: A `SignAndSendTransactionResponseData` containing the transaction signature.
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

    /// Opens a URL in the system browser.
    ///
    /// - Parameters:
    ///   - url: The URL to open.
    ///   - ref: A reference URL to append as a query parameter.
    /// - Throws: `SolanaWalletAdapterError.browsingFailure` if the URL cannot be opened.
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
