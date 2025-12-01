import Foundation
import SolanaRPC

/// A deep-link wallet adapter for the Backpack Wallet application
/// 
/// See [Backpack’s documentation](https://support.backpack.exchange/wallet/actions/add-developer-testnets.)  for more details.
public struct BackpackWallet: DeeplinkWallet {
    public static let identifier = "backpack_wallet"
    public static let _deeplinkWalletOptions = DeeplinkWalletOptions(
        baseURL: URL(string: "https://backpack.app/ul/v1")!,
        checkAvailableURL: URL(string: "backpack://hello")!,
        walletEncryptionPublicKeyIdentifier: "wallet_encryption_public_key"
    )

    public typealias Connection = DeeplinkWalletConnection

    public let appId: AppIdentity
    public let cluster: Endpoint
    public var connection: DeeplinkWalletConnection?

    /// Creates a new instance of `BackpackWallet` configured for the given
    /// application identity and Solana cluster.
    ///  
    /// - Important: BackpackWallet requires cluster to be set to mainnet. See [Backpack documentation](https://support.backpack.exchange/wallet/actions/add-developer-testnets) on how to use other clusters.
    ///
    /// - Parameters:
    ///   - appId: The identity of the dApp requesting access
    ///   - cluster: The Solana network the wallet should connect to. See ``Endpoint``
    ///   - connection: An optional existing ``Connection`` used
    ///     to restore a prior session.
    public init(
        for appId: AppIdentity, cluster: Endpoint, connection: Connection?
    ) {
        assert(
            cluster != .mainnet,
            """
            BackpackWallet requires cluster to be set to mainnet. \
            See Backpack documentation on how to use other clusters: https://support.backpack.exchange/wallet/actions/add-developer-testnets.
            """)
        self.appId = appId
        self.cluster = cluster
        self.connection = connection
    }
}
