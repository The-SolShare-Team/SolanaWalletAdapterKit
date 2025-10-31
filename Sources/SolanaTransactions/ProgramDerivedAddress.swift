import CryptoKit
import Foundation
import Salt

public struct ProgramDerivedAddress: Sendable {
    public let publicKey: PublicKey
    public let nonce: UInt8

    public static func create(programId: PublicKey, seeds: [[UInt8]]) async throws
        -> PublicKey
    {
        try await Task.detached {
            // Concatenate all seed bytes and validate their length
            let concatenatedSeeds: [UInt8] = try seeds.enumerated().reduce(into: [UInt8]()) {
                acc, next in
                let (index, seed) = next
                guard seed.count <= 32 else {
                    throw ProgramError.seedTooLong(index: index, length: seed.count)
                }
                acc.append(contentsOf: seed)
            }

            let pdaInput =
                concatenatedSeeds + programId.bytes + Array("ProgramDerivedAddress".utf8)
            let address = [UInt8](SHA256.hash(data: Data(pdaInput)))

            if try SaltUtil.isOnCurve(publicKey: Data(address)) {
                throw ProgramError.addressOnCurve
            }

            return PublicKey(bytes: address)!
        }.value
    }

    public static func find(programId: PublicKey, seeds: [[UInt8]]) async throws
        -> ProgramDerivedAddress
    {
        try await Task.detached {
            for bump in (0..<UInt8(255)).reversed() {
                guard
                    let result = try? await ProgramDerivedAddress.create(
                        programId: programId,
                        seeds: seeds + [[bump]])
                else { continue }
                return ProgramDerivedAddress(publicKey: result, nonce: bump)
            }
            throw SolanaTransactionCodingError.endOfBuffer
        }.value
    }
}
