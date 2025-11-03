import Foundation

@MainActor
public protocol SecureStorage {
    func retrieve(key: String) async throws -> Data?
    func store(_ data: Data, key: String) async throws
    func clear(key: String) async throws
}

extension SecureStorage {
    func storeWalletConnection(_ connection: WalletConnection, key: String) async throws {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(connection)
            try await store(encodedData, key: key)
        } catch let encodingError as EncodingError {
            throw SecureStorageError.encodingError(encodingError)
        } catch {
            throw SecureStorageError.storageFailure(error)
        }
    }

    func retrieveWalletConnection(key: String) async throws -> WalletConnection? {
        do {
            guard let data = try await retrieve(key: key) else {
                return nil
            }

            let decoder = JSONDecoder()
            return try decoder.decode(WalletConnection.self, from: data)
        } catch let decodingError as DecodingError {
            throw SecureStorageError.decodingError(decodingError)
        } catch {
            throw SecureStorageError.storageFailure(error)
        }
    }
}

public enum SecureStorageError: Error {
    case storageFailure(Error)
    case encodingError(Error)
    case decodingError(Error)
}

@MainActor
public class InMemorySecureStorage: SecureStorage {
    private var storage: [String: Data] = [:]

    public init() {} // simple initializer

    public func retrieve(key: String) async throws -> Data? {
        return storage[key]
    }

    public func store(_ data: Data, key: String) async throws {
        storage[key] = data
    }

    public func clear(key: String) async throws {
        storage.removeValue(forKey: key)
    }
}
