import CryptoKit
import Foundation
import SolanaRPC
import SolanaTransactions

@available(iOS 17.0, macOS 14.0, *)
@Observable
public class WalletConnectionManager {
    static let availableWalletsUserInfoKey = CodingUserInfoKey(rawValue: "availableWallets")!

    public let availableWalletsMap: [String: any Wallet.Type]
    private var storage: any SecureStorage

    public internal(set) var connectedWallets: [PublicKey: any Wallet] = [:]

    public let appIdentity: AppIdentity
    public let cluster: Endpoint

    public let appIdentity: AppIdentity
    public let cluster: Endpoint

    /// Initializes a wallet connection manager
    ///
    /// - Parameters:
    ///   - availableWallets: Optional list of wallet types supported by the manager.
    ///                       Defaults to `[SolflareWallet.self, BackpackWallet.self, PhantomWallet.self]`. See ``BackpackWallet``, ``PhantomWallet``, ``SolflareWallet``.
    ///   - storage: Secure storage instance used to save wallet connections. See ``SecureStorage``
    public init(
        appIdentity: AppIdentity,
        cluster: Endpoint,
        availableWallets: [any Wallet.Type] = [
            SolflareWallet.self,
            BackpackWallet.self,
            PhantomWallet.self,
        ],
        storage: any SecureStorage
    ) {
        self.appIdentity = appIdentity
        self.cluster = cluster
        self.availableWalletsMap = Dictionary(
            uniqueKeysWithValues: availableWallets.map { ($0.identifier, $0) })
        self.storage = storage
    }

    /// Recovers previously connected wallets from secure storage.
    ///
    /// This method attempts to decode all stored wallet connections and rebuild
    /// their corresponding `Wallet` instances. Any successfully recovered wallets
    /// are stored in the ``connectedWallets`` property.
    public func recoverWallets() async throws {
        let decoder = JSONDecoder()
        decoder.userInfo[WalletConnectionManager.availableWalletsUserInfoKey] =
            self.availableWalletsMap

        let retrieved = try await storage.retrieveAll()

        let recovered: [PublicKey: any Wallet] = Dictionary(
            uniqueKeysWithValues:
                retrieved.compactMap {
                    let saved = try? decoder.decode(SavedWalletConnection.self, from: $0.value)
                    guard let recovered = saved?.recover(),
                        let publicKey = recovered.publicKey,
                        storageKey(for: publicKey) == $0.key,
                        appIdentity == saved?.appIdentity,
                        cluster == saved?.cluster
                    else { return nil }
                    return (publicKey, recovered)
                })
        self.connectedWallets.merge(recovered) { (new, _) in new }
    }

    @discardableResult
    public func pair<W: Wallet>(_ wallet: W.Type) async throws -> any Wallet {
        var walletInstance = wallet.init(for: appIdentity, cluster: cluster)
        try await pair(&walletInstance)
        return walletInstance
    }

    /// Pairs an existing wallet instance and persists it.
    ///
    /// - Parameter wallet: A  wallet instance to connect.
    public func pair<W: Wallet>(_ wallet: inout W) async throws {
        guard let connection = try await wallet.connect() else { return }
        let savedConnection = SavedWalletConnection(wallet, connection: connection)

        let encoder = JSONEncoder()
        let data = try encoder.encode(savedConnection)
        try await storage.store(data, key: storageKey(for: savedConnection.connection.publicKey))

        connectedWallets[connection.publicKey] = wallet
    }

    /// Unpairs a wallet and removes it from secure storage.
    ///
    /// - Parameter wallet: The wallet instance to unpair.
    public func unpair<W: Wallet>(_ wallet: inout W) async throws {
        guard let publicKey = wallet.publicKey else { throw SolanaWalletAdapterError.notConnected }
        try await wallet.disconnect()
        connectedWallets.removeValue(forKey: publicKey)
        try await storage.clear(key: storageKey(for: publicKey))
    }

    func storageKey(for publicKey: PublicKey) -> String {
        return "\(appIdentity.name):\(cluster.url.absoluteString):\(cluster):\(publicKey.description)"
    }
}
