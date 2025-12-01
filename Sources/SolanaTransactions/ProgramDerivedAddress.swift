import CryptoKit
import Foundation
import Salt

/// A Program Dervied Address (PDA) is an address that is created deterministically using a program ID and a combination of optional predefined inputs.
///
/// For more information, see [Solana Docs](https://solana.com/docs/core/pda).
///
/// ## Methods
/// - ``create(programId:seeds:)``
/// - ``find(programId:seeds:)``
public struct ProgramDerivedAddress: Sendable {
    public let publicKey: PublicKey
    public let nonce: UInt8

    /// Creates a Program Derived Address (PDA) for a given program using the provided seeds.
    ///
    /// PDA is a deterministic public key derived from a program ID and seed values. This method returns the PDA’s `PublicKey`.
    ///
    /// - Parameters:
    ///   - programId: The public key of the program for which the PDA is being generated.
    ///   - seeds: An array of byte arrays used as seeds to derive the PDA.
    /// - Returns: The derived `PublicKey` representing the PDA.
    @concurrent
    public static func create(programId: PublicKey, seeds: [[UInt8]]) async throws -> PublicKey {
        // Concatenate all seed bytes and validate their length
        let concatenatedSeeds: [UInt8] = try seeds.enumerated().reduce(into: [UInt8]()) { acc, next in
            let (index, seed) = next
            guard seed.count <= 32 else {
                throw ProgramDerivedAddressError.seedTooLong(
                    index: index, length: seed.count)
            }
            acc.append(contentsOf: seed)
        }

        let pdaInput =
            concatenatedSeeds + programId.bytes + Array("ProgramDerivedAddress".utf8)
        let address = Data(SHA256.hash(data: Data(pdaInput)))

        if try SaltUtil.isOnCurve(publicKey: address) {
            throw ProgramDerivedAddressError.addressOnCurve
        }

        return PublicKey(bytes: address)!
    }

    /// Finds a valid Program Derived Address (PDA) for a program using the provided seeds.
    ///
    /// This method attempts to generate a PDA by appending a bump seed (0–255) to the seeds array.
    ///
    /// - Parameters:
    ///   - programId: The public key of the program for which the PDA is being derived.
    ///   - seeds: An array of byte arrays used as seeds to derive the PDA.
    /// - Returns: A `ProgramDerivedAddress` containing the valid PDA and the bump seed used.
    /// - Throws: If the seed at a certain index is too long or there are invalid seeds, an error will throw. See ``ProgramDerivedAddress``.
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

/// Errors that can occur when generating a Program Derived Address (PDA).
///
/// Two possible errors:
/// 1. Seed at index is too long, must be <= 32 bytes.
/// 2. Invalid seeds: derived address falls on the ed25519 curve.
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
