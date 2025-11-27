import Foundation
import SolanaRPC

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

    public init(
        for appId: AppIdentity, cluster: Endpoint, connection: Connection?
    ) {
        self.appId = appId
        self.cluster = cluster
        self.connection = connection
    }
}
