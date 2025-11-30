import CryptoKit
import Foundation

/// Represents a Solana program, providing a consistent interface
/// for accessing the program's ID and for working with Program Derived Addresses (PDAs).
///
/// This protocol is used as a base for program abstractions,
/// allowing easy derivation of addresses and interaction with Solana programs. See ``AssociatedTokenProgram``, ``MemoProgram``, ``SystemProgram``, ``TokenProgram``.
///
/// ## Methods
/// - ``createDerivedAddress(seeds:)``
/// - ``findDerivedAddress(seeds:)``
public protocol Program {
    static var programId: PublicKey { get }

    // static func createDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey
    static func findDerivedAddress(seeds: [[UInt8]]) async throws -> ProgramDerivedAddress
}

extension Program {
    public var programId: PublicKey {
        Self.programId
    }

    /// Creates a Program Derived Address (PDA) for this program using the given seeds.
    ///
    /// A PDA is a deterministic public key derived from the program ID and seed values.
    /// This method returns only the `PublicKey` of the PDA.
    ///
    /// - Parameter seeds: An array of byte arrays used as seeds to derive the PDA.
    /// - Returns: The derived `PublicKey`.
    /// - Throws: An error if the PDA cannot be created.
    public static func createDerivedAddress(seeds: [[UInt8]]) async throws -> PublicKey {
        return try await ProgramDerivedAddress.create(programId: Self.programId, seeds: seeds)
    }

    /// Finds a Program Derived Address (PDA) for this program using the given seeds.
    ///
    /// This method returns a `ProgramDerivedAddress` object, which includes both the PDA public key and the bump seed used to make the PDA valid on Solana.
    ///
    /// - Parameter seeds: An array of byte arrays used as seeds to derive the PDA.
    /// - Returns: A `ProgramDerivedAddress` object containing the PDA and bump seed.
    /// - Throws: An error if the PDA cannot be found.
    public static func findDerivedAddress(seeds: [[UInt8]]) async throws -> ProgramDerivedAddress {
        try await ProgramDerivedAddress.find(programId: Self.programId, seeds: seeds)
    }
}
