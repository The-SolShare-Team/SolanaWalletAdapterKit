import Foundation
import SolanaRPC

public class SolflareWallet: DeeplinkWallet {
    public static var baseURL: URL = URL(string: "https://solflare.com/ul/v1")!
    public var connection: WalletConnection?
    public var appId: AppIdentity
    public var cluster: SolanaRPC.Endpoint
    public var secureStorage: SecureStorage

    public required init(
        for appId: AppIdentity,
        cluster: SolanaRPC.Endpoint,
        restoreFrom secureStorage: SecureStorage
    ) async throws {
        self.appId = appId
        self.cluster = cluster
        self.secureStorage = secureStorage
        self.connection = try await secureStorage.retrieveWalletConnection(
            key: self.secureStorageKey)
    }

    public func pair() async throws {
        try await pair(walletEncryptionPublicKeyIdentifier: "solflare_encryption_public_key")
    }
}
