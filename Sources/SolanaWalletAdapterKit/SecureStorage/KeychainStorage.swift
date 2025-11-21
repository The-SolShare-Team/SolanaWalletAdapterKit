import Foundation
import SimpleKeychain

public struct KeychainStorage: SecureStorage {
    let keychain: SimpleKeychain

    public init(
        service: String = "SolanaWalletAdapterKit",
        accessibility: Accessibility = .whenUnlockedThisDeviceOnly
    ) {
        self.keychain = SimpleKeychain(service: service, accessibility: accessibility)
    }

    public init(_ keychain: SimpleKeychain) {
        self.keychain = keychain
    }

    public func retrieve(key: String) async throws -> Data {
        return try keychain.data(forKey: key)
    }

    public func retrieveAll() async throws -> [String: Data] {
        return Dictionary(
            uniqueKeysWithValues: try keychain.keys().map { ($0, try keychain.data(forKey: $0)) }
        )
    }

    public func store(_ data: Data, key: String) async throws {
        try keychain.set(data, forKey: key)
    }

    public func clear(key: String) async throws {
        try keychain.deleteItem(forKey: key)
    }
}
