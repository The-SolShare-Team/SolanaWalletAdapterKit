import CryptoKit
import Foundation
import SolanaRPC
import SolanaTransactions

/// Manages connections to multiple Solana wallets, handling pairing, unpairing,
/// and recovery of previously connected wallets.
///
/// This class supports any wallet conforming to the `Wallet` protocol, and
/// persists connection data using a secure storage mechanism.
///
/// Use this class to either connect a wallet to your app, recover previously connected wallets or unpair wallets and remove them from secure storage.
public class WalletConnectionManager {
    static let availableWalletsUserInfoKey = CodingUserInfoKey(rawValue: "availableWallets")!

    public let availableWalletsMap: [String: any Wallet.Type]
    private var storage: any SecureStorage

    public internal(set) var connectedWallets: [PublicKey: any Wallet] = [:]

    public let appIdentity: AppIdentity
    public let cluster: Endpoint

    /// Initializes a wallet connection manager
    ///
    /// - Parameters:
    ///   - availableWallets: Optional list of wallet types supported by the manager.
    ///                       Defaults to `[SolflareWallet.self, BackpackWallet.self, PhantomWallet.self]`. See ``BackpackWallet``, ``PhantomWallet``, ``SolflareWallet``.
    ///   - storage: Secure storage instance used to save wallet connections. See ``SecureStorage``
    public init(
        availableWallets: [any Wallet.Type] = [
            SolflareWallet.self,
            BackpackWallet.self,
            PhantomWallet.self,
        ],
        storage: any SecureStorage
    ) {
        self.availableWallets = availableWallets
        self.availableWallets = availableWallets
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

        self.connectedWallets = try await storage.retrieveAll().compactMap {
            let saved = try? decoder.decode(SavedWalletConnection.self, from: $0.value)
            return saved?.recover()
        }
    }

    /// Pairs a wallet of the specified type for a given app and cluster.
    ///
    /// - Parameters:
    ///   - wallet: The wallet type to pair (e.g., `PhantomWallet.self`).
    ///   - appIdentity: The identity of the app using the wallet. See ``AppIdentity``.
    ///   - cluster: The Solana cluster endpoint (e.g., `.devnet`, `.mainnet`).
    /// - Returns: The connected wallet instance.
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
    public func pair<W: Wallet>(_ wallet: W.Type, for appIdentity: AppIdentity, cluster: Endpoint)
        async throws -> any Wallet
    {
    public func pair<W: Wallet>(_ wallet: W.Type, for appIdentity: AppIdentity, cluster: Endpoint)
        async throws -> any Wallet
    {
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
        try await storage.store(data, key: try savedConnection.identifier())
        try await storage.store(data, key: savedConnection.connection.publicKey.description)

        connectedWallets.append(wallet)
    }

    /// Unpairs a wallet and removes it from secure storage.
    ///
    /// - Parameter wallet: The wallet instance to unpair.
    public func unpair<W: Wallet>(_ wallet: inout W) async throws {
        guard let publicKey = wallet.publicKey else { throw SolanaWalletAdapterError.notConnected }
        let identifier = try Self.walletIdentifier(
            for: type(of: wallet), appIdentity: wallet.appId, cluster: wallet.cluster,
            publicKey: publicKey)
        try await wallet.disconnect()
        connectedWallets.removeAll {
            $0.appId == wallet.appId && $0.cluster == wallet.cluster && $0.publicKey == publicKey
                && type(of: $0) == type(of: wallet)
        }
        try await storage.clear(key: identifier)
    }

    static func walletIdentifier(
        for walletType: any Wallet.Type, appIdentity: AppIdentity, cluster: Endpoint,
        publicKey: PublicKey
    ) throws
        -> String
    {
        struct Identifier: Codable {
            let walletType: String
            let appIdentity: AppIdentity
            let cluster: Endpoint
            let publicKey: PublicKey
        }
        let identifier = Identifier(
            walletType: walletType.identifier, appIdentity: appIdentity, cluster: cluster,
            publicKey: publicKey)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(identifier)
        let hash = SHA256.hash(data: encoded)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
        connectedWallets.removeValue(forKey: publicKey)
        try await storage.clear(key: identifier)
    }
}
