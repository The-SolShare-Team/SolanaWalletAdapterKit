import CryptoKit
import Foundation

public protocol Program {
    static var programId: PublicKey { get }

    static func createDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey
    static func findDerivedAddress(seeds: [[UInt8]]) async throws -> ProgramDerivedAddress
}

extension Program {
    public var programId: PublicKey {
        Self.programId
    }

    public static func createDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey {
        try await ProgramDerivedAddress.create(programId: Self.programId, seeds: seeds)
    }

    public static func findDerivedAddress(seeds: [[UInt8]]) async throws -> ProgramDerivedAddress {
        try await ProgramDerivedAddress.find(programId: Self.programId, seeds: seeds)
    }
}

public enum ProgramError: Error, CustomStringConvertible {
    case seedTooLong(index: Int, length: Int)
    case addressOnCurve

    public var description: String {
        switch self {
        case .seedTooLong(let index, let length):
            "Seed at index \(index) too long (\(length) bytes). Must be <= 32 bytes."
        case .addressOnCurve:
            "Invalid seeds: derived address falls on the ed25519 curve."
        }
    }
}
