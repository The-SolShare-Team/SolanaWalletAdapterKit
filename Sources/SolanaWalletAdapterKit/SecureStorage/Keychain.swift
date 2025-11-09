import Foundation
import SimpleKeychain

public struct Keychain: SecureStorage {
    public init() {}
    
    // TODO: Not sure if the service should be hardcoded
    let keychain = SimpleKeychain(
        service: "SolanaWalletAdapterKit", accessibility: .whenUnlockedThisDeviceOnly)

    public func retrieve(key: String) async throws -> Data? {
        return try? keychain.data(forKey: key)
    }

    public func store(_ data: Data, key: String) async throws {
        try? keychain.set(data, forKey: key)
    }

    public func clear(key: String) async throws {
        try? keychain.deleteItem(forKey: key)
    }
}
