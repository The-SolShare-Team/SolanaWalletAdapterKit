import SolanaRPC

@available(iOS 17.0, macOS 14.0, *)
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

        guard
            let availableWallets =
                decoder.userInfo[WalletConnectionManager.availableWalletsUserInfoKey]
                as? [String: any Wallet.Type]
        else {
            throw DecodingError.dataCorruptedError(
                forKey: .walletType, in: container,
                debugDescription: "Missing or invalid availableWallets in decoder.userInfo")
        }

        guard let walletType = availableWallets[walletIdentifier] else {
            throw DecodingError.dataCorruptedError(
                forKey: .walletType, in: container,
                debugDescription: "Unknown wallet identifier: \(walletIdentifier)")
        }
        self.walletType = walletType

        self.connection = try container.decode(
            walletType.ConnectionType.self, forKey: .connection)

        self.appIdentity = try container.decode(AppIdentity.self, forKey: .appIdentity)
        self.cluster = try container.decode(Endpoint.self, forKey: .cluster)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(walletType.identifier, forKey: .walletType)
        try container.encode(appIdentity, forKey: .appIdentity)
        try container.encode(cluster, forKey: .cluster)
        try container.encode(connection, forKey: .connection)
    }

    func recover() -> any Wallet {
        walletType.recover(for: appIdentity, cluster: cluster, connection: connection)
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
        // swiftlint:disable:next force_cast
        self.init(for: appIdentity, cluster: cluster, connection: (connection as! Connection))
    }
}
