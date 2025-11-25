import CryptoKit
import Foundation
import SolanaRPC
import SolanaTransactions

public class WalletConnectionManager {
    static let availableWalletsUserInfoKey = CodingUserInfoKey(rawValue: "availableWallets")!

    public let availableWalletsMap: [String: any Wallet.Type]
    public let availableWallets: [any Wallet.Type]
    private var storage: any SecureStorage

    public private(set) var connectedWallets: [any Wallet] = []

    public init(
        availableWallets: [any Wallet.Type] = [
            SolflareWallet.self,
            BackpackWallet.self,
            PhantomWallet.self,
        ],
        storage: any SecureStorage
    ) {
        self.availableWallets = availableWallets
        self.availableWalletsMap = Dictionary(
            uniqueKeysWithValues: availableWallets.map { ($0.identifier, $0) })
        self.storage = storage
    }

    public func recoverWallets() async throws {
        let decoder = JSONDecoder()
        decoder.userInfo[WalletConnectionManager.availableWalletsUserInfoKey] =
            self.availableWalletsMap

        print(try await storage.retrieveAll())

        self.connectedWallets = try await storage.retrieveAll().compactMap {
            let saved = try? decoder.decode(SavedWalletConnection.self, from: $0.value)
            return saved?.recover()
        }
    }

    public func pair<W: Wallet>(_ wallet: W.Type, for appIdentity: AppIdentity, cluster: Endpoint)
        async throws
    {
        var walletInstance = wallet.init(for: appIdentity, cluster: cluster)
        try await pair(&walletInstance)
    }

    public func pair<W: Wallet>(_ wallet: inout W) async throws {
        guard let connection = try await wallet.connect() else { return }
        let savedConnection = SavedWalletConnection(wallet, connection: connection)

        let encoder = JSONEncoder()
        let data = try encoder.encode(savedConnection)
        try await storage.store(data, key: try savedConnection.identifier())
        print(try savedConnection.identifier())
        print(try await storage.retrieve(key: try savedConnection.identifier()))
        connectedWallets.append(wallet)
    }

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

    static func walletIdentifier(  // TODO: Make this not random
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
        let encoded = try encoder.encode(identifier)
        let hash = SHA256.hash(data: encoded)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
