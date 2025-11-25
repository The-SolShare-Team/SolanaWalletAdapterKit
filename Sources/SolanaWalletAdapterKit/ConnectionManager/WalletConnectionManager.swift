import CryptoKit
import Foundation
import SolanaRPC
import SolanaTransactions

public class WalletConnectionManager {
    static let availableWalletsUserInfoKey = CodingUserInfoKey(rawValue: "availableWallets")!

    public let availableWalletsMap: [String: any Wallet.Type]
    public let availableWallets: [any Wallet.Type]
    private var storage: any SecureStorage

    public internal(set) var connectedWallets: [any Wallet] = []

    public init(
        availableWallets: [any Wallet.Type] = [SolflareWallet.self], storage: any SecureStorage
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
        
        print("Recovering wallets, printing all storage keys:")
        print(try await storage.retrieveAll())

        self.connectedWallets = try await storage.retrieveAll().compactMap {
            let saved = try? decoder.decode(SavedWalletConnection.self, from: $0.value)
            return saved?.recover()
        }
    }

    public func pair<W: Wallet>(_ wallet: W.Type, for appIdentity: AppIdentity, cluster: Endpoint)
        async throws -> Wallet
    {
        var walletInstance = wallet.init(for: appIdentity, cluster: cluster)
        try await pair(&walletInstance)
        return walletInstance
    }

    public func pair<W: Wallet>(_ wallet: inout W) async throws {
        guard let connection = try await wallet.connect() else { return }
        guard let publicKey = wallet.publicKey else { return }
        let savedConnection = SavedWalletConnection(wallet, connection: connection)

        let encoder = JSONEncoder()
        let data = try encoder.encode(savedConnection)
        let identifier = try savedConnection.identifier()
        try await storage.store(data, key: identifier)
//        print("Saved Connection Identifier: " +  identifier)
//        print("All keys in storage:")
//        print(try await storage.retrieveAll().map(\.key))
//        print("Retrieving from Storage Identifier: " +  identifier)
//        print(try await storage.retrieve(key: identifier))
        connectedWallets.append(wallet)
    }

    public func unpair<W: Wallet>(_ wallet: inout W) async throws {
        guard let connection = wallet.connection, let publicKey = wallet.publicKey else { throw SolanaWalletAdapterError.notConnected }
        let decoder = JSONDecoder()
            decoder.userInfo[WalletConnectionManager.availableWalletsUserInfoKey] = self.availableWalletsMap
        
        
        connectedWallets.removeAll {
            $0.appId == wallet.appId && $0.cluster == wallet.cluster && $0.publicKey == publicKey
                && type(of: $0) == type(of: wallet)
        }
        let identifier = try WalletConnectionManager.walletIdentifier(for: type(of: wallet), appIdentity: wallet.appId, cluster: wallet.cluster, publicKey: publicKey)
//        print("Identifier to disconnect: ")
//        print(identifier)
//        print("All keys in storage:")
//        print(try await storage.retrieveAll().map(\.key))
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
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(identifier)
        let hash = SHA256.hash(data: encoded)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
