import Foundation
import SolanaTransactions
import SwiftBorsh

extension SolanaRPCClient {
    @discardableResult
    public func requestAirdrop(
        to address: PublicKey,
        lamports: UInt64,
    ) async throws -> Signature {
        try await fetch(
            method: "requestAirdrop",
            params: [address, lamports],
            into: Signature.self
        )
    }
}
