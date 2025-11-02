import Foundation
import SwiftBorsh
import SolanaTransactions

extension SolanaRPCClient {
    public func requestAirdrop(
        to address: String,
        lamports: UInt64,
    ) async throws {
        _ = try await fetch(
            method: "requestAirdrop",
            params: [address, lamports],
            into: String.self
        )
    }
}