import Foundation
import SwiftBorsh
import SolanaTransactions

extension SolanaRPCClient {
    public func getMinBalanceForRentExemption(
        accountDataLength: UInt64,
    ) async throws -> UInt64 {
        try await fetch(
            method: "getMinimumBalanceForRentExemption",
            params: [accountDataLength],
            into: UInt64.self
        )
    }
}