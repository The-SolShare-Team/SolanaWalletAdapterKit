import CryptoKit
import Foundation

public protocol Program {
    static var programId: PublicKey { get }

    func createDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey
    // func findDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey
}

extension Program {
    public var programId: PublicKey {
        Self.programId
    }

    public func createDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey? {  // TODO: Remove optional?
        // Concatenate all seed bytes and validate their length
        let concatenatedSeeds: [UInt8] = try seeds.enumerated().reduce(into: [UInt8]()) {
            acc, next in
            let (index, seed) = next
            guard seed.count <= 32 else {
                throw ProgramError.seedTooLong(index: index, length: seed.count)
            }
            acc.append(contentsOf: seed)
        }

        let pdaInput = concatenatedSeeds + programId.bytes + Array("ProgramDerivedAddress".utf8)
        let address = [UInt8](SHA256.hash(data: Data(pdaInput)))

        // Reject if on curve
        if address.isOnCurve() {  // TODO: Use TweetNacl to verify if it's on the curve
            throw ProgramError.addressOnCurve
        }

        return PublicKey(bytes: address)
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
