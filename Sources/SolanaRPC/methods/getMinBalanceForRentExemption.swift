import Foundation
import SwiftBorsh

extension SolanaRPCClient {
    /// Configuration options for the ``getMinBalanceForRentExemption(accountDataLength:configuration:)`` RPC request.
    ///
    /// This struct allows you to provide **optional parameters** when requesting the minimum balance of rent exemption from the Solana blockchain. All properties are optional,
    /// so you can specify only the values you need.
    /// 
    ///```
    ///public init(
    ///     commitment: Commitment? = nil
    ///) {
    ///     self.commitment = commitment
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - commitment: The commitment level indicates how confirmed a block is at the time of the query. See ``Commitment``.
    ///

    public struct GetMinBalanceForRentExemptionConfiguration: Encodable {
        let commitment: Commitment?

        public init(
            commitment: Commitment? = nil
        ) {
            self.commitment = commitment
        }
    }

    /// See [getMinimumBalanceForRentExemption](https://solana.com/docs/rpc/http/getminimumbalanceforrentexemption) implementation on Solana Docs.
    ///
    /// This method sends a `getMinBalanceForRentExemption` RPC request to the Solana network. You can optionally provide a
    /// ``GetMinBalanceForRentExemptionConfiguration`` to control things like the commitment level.
    /// - Throws: `RPCError` if the request fails or the response is invalid.
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
