import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC
import SolanaTransactions

public struct SolflareWallet: DeeplinkWallet {
    public static let identifier = "solflare_wallet"
    public static let baseURL: URL = URL(string: "https://solflare.com/ul/v1")!
    public static let walletEncryptionPublicKeyIdentifier: String = "solflare_encryption_public_key"

    public typealias Connection = DeeplinkWalletConnection

    public let appId: AppIdentity
    public let cluster: Endpoint
    public var connection: DeeplinkWalletConnection?
    public var publicKey: PublicKey? { connection?.walletPublicKey }

    public init(
        for appId: AppIdentity, cluster: Endpoint, connection: Connection?
    ) {
        self.appId = appId
        self.cluster = cluster
        self.connection = connection
    }
}
