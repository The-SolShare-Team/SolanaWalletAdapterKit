import CryptoKit
import Foundation
import Salt

public struct ProgramDerivedAddress: Sendable {
    public let publicKey: PublicKey
    public let nonce: UInt8

    @concurrent
    public static func create(programId: PublicKey, seeds: [[UInt8]]) async throws -> PublicKey {
        // Concatenate all seed bytes and validate their length
        let concatenatedSeeds: [UInt8] = try seeds.enumerated().reduce(into: [UInt8]()) {
            acc, next in
            let (index, seed) = next
            guard seed.count <= 32 else {
                throw ProgramDerivedAddressError.seedTooLong(
                    index: index, length: seed.count)
            }
            acc.append(contentsOf: seed)
        }

        let pdaInput =
            concatenatedSeeds + programId.bytes + Array("ProgramDerivedAddress".utf8)
        let address = [UInt8](SHA256.hash(data: Data(pdaInput)))

        if try SaltUtil.isOnCurve(publicKey: Data(address)) {
            throw ProgramDerivedAddressError.addressOnCurve
        }

        return PublicKey(bytes: address)!

    }

    @concurrent
    public static func find(programId: PublicKey, seeds: [[UInt8]]) async throws
        -> ProgramDerivedAddress
    {
        for bump in (0..<UInt8(255)).reversed() {
            guard
                let result = try? await ProgramDerivedAddress.create(
                    programId: programId,
                    seeds: seeds + [[bump]])
            else { continue }
            return ProgramDerivedAddress(publicKey: result, nonce: bump)
        }
        throw ProgramDerivedAddressError.addressOnCurve
    }
}

public enum ProgramDerivedAddressError: Error, CustomStringConvertible {
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
