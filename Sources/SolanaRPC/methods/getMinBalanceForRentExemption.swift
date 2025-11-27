import Foundation
import SwiftBorsh

extension SolanaRPCClient {
    public struct GetMinBalanceForRentExemptionConfiguration: Encodable {
        let commitment: Commitment?

        public init(
            commitment: Commitment? = nil
        ) {
            self.commitment = commitment
        }
    }

    /// https://solana.com/docs/rpc/http/getminimumbalanceforrentexemption
    public func getMinBalanceForRentExemption(
        accountDataLength: UInt64,
        configuration: GetMinBalanceForRentExemptionConfiguration? = nil
    ) async throws(RPCError) -> UInt64 {
        var params: [Encodable] = [accountDataLength]
        if let configuration {
            params.append(configuration)
        }

        return try await fetch(
            method: "getMinimumBalanceForRentExemption",
            params: params,
            into: UInt64.self
        )
    }
}
