import CryptoKit
import Foundation

public protocol Program {
    static var programId: PublicKey { get }

    // static func createDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey
    static func findDerivedAddress(seeds: [[UInt8]]) async throws -> ProgramDerivedAddress
}

extension Program {
    public var programId: PublicKey {
        Self.programId
    }

    public static func createDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey {
        return try await ProgramDerivedAddress.create(programId: Self.programId, seeds: seeds)
    }

    public static func findDerivedAddress(seeds: [[UInt8]]) async throws -> ProgramDerivedAddress {
        try await ProgramDerivedAddress.find(programId: Self.programId, seeds: seeds)
    }
}
