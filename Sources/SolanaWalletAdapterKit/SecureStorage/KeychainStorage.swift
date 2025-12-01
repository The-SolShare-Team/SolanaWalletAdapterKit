import Foundation
import SimpleKeychain

/// A secure storage implementation using the system keychain.
///
/// `KeychainStorage` allows storing, retrieving, and deleting arbitrary data
/// securely on the device using Apple's Keychain APIs via `SimpleKeychain`.
///
/// This is typically used to persist wallet connections, encrypted sessions,
/// or any sensitive data required by a Solana Wallet Adapter.
public struct KeychainStorage: SecureStorage {
    let keychain: SimpleKeychain

    /// Creates a new `KeychainStorage` with a specified service name and accessibility.
    ///
    /// - Parameters:
    ///   - service: The keychain service name used to namespace stored items.
    ///     Defaults to `"SolanaWalletAdapterKit"`.
    ///   - accessibility: The keychain accessibility setting determining when
    ///     the stored data can be accessed. Defaults to `.whenUnlockedThisDeviceOnly`.
    public init(
        service: String = "SolanaWalletAdapterKit",
        accessibility: Accessibility = .whenUnlockedThisDeviceOnly
    ) {
        self.keychain = SimpleKeychain(service: service, accessibility: accessibility)
    }

    /// Creates a new `KeychainStorage` wrapping an existing `SimpleKeychain` instance.
    ///
    /// - Parameter keychain: An existing `SimpleKeychain` instance to use.
    public init(_ keychain: SimpleKeychain) {
        self.keychain = keychain
    }

    /// Retrieves a value for the given key from the keychain.
    ///
    /// - Parameter key: The key for which to retrieve the data.
    /// - Returns: The data stored for the given key.
    /// - Throws: Throws an error if the key is not found or if the keychain
    ///   access fails.
    public func retrieve(key: String) async throws -> Data {
        return try keychain.data(forKey: key)
    }

    /// Retrieves all key-value pairs stored in the keychain.
    ///
    /// - Returns: A dictionary of all keys and their associated data.
    /// - Throws: Throws an error if retrieving any key or data fails.
    public func retrieveAll() async throws -> [String: Data] {
        return Dictionary(
            uniqueKeysWithValues: try keychain.keys().map { ($0, try keychain.data(forKey: $0)) }
        )
    }

    /// Stores data in the keychain for a given key.
    ///
    /// - Parameters:
    ///   - data: The data to store.
    ///   - key: The key under which to store the data.
    /// - Throws: Throws an error if storing the data fails.
    public func store(_ data: Data, key: String) async throws {
        try keychain.set(data, forKey: key)
    }

    /// Removes a value from the keychain for the given key.
    ///
    /// - Parameter key: The key for which to remove the stored data.
    /// - Throws: Throws an error if deletion fails or the key does not exist.
    public func clear(key: String) async throws {
        try keychain.deleteItem(forKey: key)
    }
}
