import Foundation
import SolanaRPC

/// A deep-link wallet adapter for the Solflare Wallet application
public struct SolflareWallet: DeeplinkWallet {
    public static let identifier = "solflare_wallet"
    public static let _deeplinkWalletOptions = DeeplinkWalletOptions(
        baseURL: URL(string: "https://solflare.com/ul/v1")!,
        checkAvailableURL: URL(string: "solflare://hello")!,
        walletEncryptionPublicKeyIdentifier: "solflare_encryption_public_key"
    )

    public typealias Connection = DeeplinkWalletConnection

    public let appId: AppIdentity
    public let cluster: Endpoint
    public var connection: DeeplinkWalletConnection?

    /// Creates a new instance of `SolflareWallet` configured for the given
    /// application identity and Solana cluster.
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
    }
}
