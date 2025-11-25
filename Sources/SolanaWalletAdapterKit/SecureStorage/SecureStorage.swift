import Foundation

public protocol SecureStorage {
    func retrieve(key: String) async throws -> Data
    func retrieveAll() async throws -> [String: Data]
    func store(_ data: Data, key: String) async throws
    func clear(key: String) async throws
}
