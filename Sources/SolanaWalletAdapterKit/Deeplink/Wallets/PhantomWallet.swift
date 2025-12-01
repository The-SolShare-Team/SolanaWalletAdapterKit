import Foundation
import SolanaRPC
import SolanaTransactions

/// A deep-link wallet adapter for the Phantom Wallet application
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

    private let rpcClient: SolanaRPCClient

    /// Creates a new instance of `PhantomWallet` configured for the given
    /// application identity and Solana cluster.
    ///
    ///  **Note**:  As Phantom does not currently have a `SignAndSendTransaction`, the current implementation of ``signAndSendTransaction(transaction:sendOptions:)``, signs the transaction through Phantom, but sends the transaction through the RPC client.
    ///
    /// - Parameters:
    ///   - appId: The identity of the dApp requesting access
    ///   - cluster: The Solana network the wallet should connect to. See ``Endpoint``
    ///   - connection: An optional existing ``Connection`` used
    ///     to restore a prior session.
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
        let signature = try await rpcClient.sendTransaction(
            transaction: response.transaction,
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
}
