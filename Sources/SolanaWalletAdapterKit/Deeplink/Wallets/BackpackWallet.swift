import Foundation
import SolanaRPC
import SolanaTransactions

public struct BackpackWallet: DeeplinkWallet {
    public static let identifier = "phantom_wallet"
    public static let _deeplinkWalletOptions = DeeplinkWalletOptions(
        baseURL: URL(string: "https://backpack.app/ul/v1")!,
        checkAvailableURL: URL(string: "backpack://hello")!,
        walletEncryptionPublicKeyIdentifier: "wallet_xxx"
    )

    public typealias Connection = DeeplinkWalletConnection

    public let appId: AppIdentity
    public let cluster: Endpoint
    public var connection: DeeplinkWalletConnection?
    public var publicKey: PublicKey? { connection?.publicKey }

    public init(
        for appId: AppIdentity, cluster: Endpoint, connection: Connection?
    ) {
        self.appId = appId
        self.cluster = cluster
        self.connection = connection
    }
}
