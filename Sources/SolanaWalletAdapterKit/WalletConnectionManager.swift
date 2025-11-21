import Foundation
import SolanaRPC

public class WalletConnectionManager {
    static let availableWalletsUserInfoKey = CodingUserInfoKey(rawValue: "availableWallets")!

    struct SavedWalletConnection: Codable {
        let walletType: any Wallet.Type
        let connection: any WalletConnection
        let appIdentity: AppIdentity
        let cluster: Endpoint

        enum CodingKeys: String, CodingKey {
            case walletType
            case appIdentity
            case cluster
            case connection
        }

        init<W: Wallet>(_ wallet: W, connection: W.Connection) {
            self.walletType = type(of: wallet)
            self.connection = connection
            self.appIdentity = wallet.appId
            self.cluster = wallet.cluster
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let walletIdentifier = try container.decode(String.self, forKey: .walletType)

            let availableWallets =
                decoder.userInfo[availableWalletsUserInfoKey] as? [String: any Wallet.Type]
                ?? [:]

            self.walletType = availableWallets[walletIdentifier]!
            self.connection = try walletType.ConnectionType.init(from: decoder)
            self.appIdentity = try container.decode(AppIdentity.self, forKey: .appIdentity)
            self.cluster = try container.decode(Endpoint.self, forKey: .cluster)
        }

        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(walletType.identifier, forKey: .walletType)
            try container.encode(appIdentity, forKey: .appIdentity)
            try container.encode(cluster, forKey: .cluster)
        }

        func recover() -> any Wallet {
            walletType.recover(for: appIdentity, cluster: cluster, connection: connection)
        }

        func identifier() -> String {
            WalletConnectionManager.walletIdentifier(
                for: walletType, appIdentity: appIdentity, cluster: cluster)
        }
    }

    public let availableWallets: [String: any Wallet.Type]
    private var storage: any SecureStorage

    public private(set) var connectedWallets: [any Wallet]

    public init(availableWallets: [any Wallet.Type], storage: any SecureStorage) async throws {
        self.availableWallets = Dictionary(
            uniqueKeysWithValues: availableWallets.map { ($0.identifier, $0) })
        self.storage = storage

        let decoder = JSONDecoder()
        decoder.userInfo[WalletConnectionManager.availableWalletsUserInfoKey] =
            self.availableWallets

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
        try await storage.store(data, key: savedConnection.identifier())
        connectedWallets.append(wallet)
    }

    public func unpair<W: Wallet>(_ wallet: inout W) async throws {
        let identifier = Self.walletIdentifier(
            for: type(of: wallet), appIdentity: wallet.appId, cluster: wallet.cluster)
        try await wallet.disconnect()
        connectedWallets.removeAll {
            $0.appId == wallet.appId && $0.cluster == wallet.cluster
                && type(of: $0) == type(of: wallet)
        }
        try await storage.clear(key: identifier)
    }

    static func walletIdentifier(
        for walletType: any Wallet.Type, appIdentity: AppIdentity, cluster: Endpoint
    )
        -> String
    {
        var hasher = Hasher()
        hasher.combine(walletType.identifier)
        hasher.combine(appIdentity)
        hasher.combine(cluster)
        return String(hasher.finalize())
    }
}

// For typing purposes
extension Wallet {
    fileprivate static var ConnectionType: Connection.Type {
        Connection.self
    }

    fileprivate static func recover(
        for appIdentity: AppIdentity, cluster: Endpoint, connection: WalletConnection
    ) -> Self {
        self.init(for: appIdentity, cluster: cluster, connection: (connection as! Connection))
    }
}
