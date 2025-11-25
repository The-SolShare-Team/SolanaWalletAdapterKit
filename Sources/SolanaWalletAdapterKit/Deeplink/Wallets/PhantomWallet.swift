import Foundation
import SolanaRPC
import SolanaTransactions

public struct PhantomWallet: DeeplinkWallet {
    public static let identifier = "phantom_wallet"
    public static let _deeplinkWalletOptions = DeeplinkWalletOptions(
        baseURL: URL(string: "https://phantom.app/ul/v1")!,
        checkAvailableURL: URL(string: "phantom://hello")!,
        walletEncryptionPublicKeyIdentifier: "phantom_encryption_public_key"
    )

    public typealias Connection = DeeplinkWalletConnection

    public let appId: AppIdentity
    public let cluster: Endpoint
    public var connection: DeeplinkWalletConnection?
    public var publicKey: PublicKey? { connection?.publicKey }

    private let rpcClient: SolanaRPCClient

    public init(
        for appId: AppIdentity, cluster: Endpoint, connection: Connection?
    ) {
        self.appId = appId
        self.cluster = cluster
        self.connection = connection
        self.rpcClient = SolanaRPCClient(endpoint: cluster)
    }

    /// Sign and send a transaction. Because Phantom has deprecated the
    /// `signAndSendTransaction` deeplink endpoint, this method serves as a
    /// polyfill: it first invokes the `signTransaction` deeplink endpoint,
    /// then broadcasts the signed transaction natively.
    public func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions? = nil)
        async throws -> SignAndSendTransactionResponseData
    {
        let response = try await self.signTransaction(transaction: transaction)
        guard let transactionData = Data(base58Encoded: response.transaction) else {
            throw SolanaWalletAdapterError.responseDecodingFailure
        }
        let transaction = try Transaction(bytes: transactionData)
        let signature = try await rpcClient.sendTransaction(
            transaction: transaction,
            configuration: TransactionOptions(sendOptions: sendOptions, encoding: .base58)
        )
        return SignAndSendTransactionResponseData(signature: signature)
    }
}
