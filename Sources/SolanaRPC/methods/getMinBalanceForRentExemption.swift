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
    ///   - commitment: The commitment describes how finalized a block is at that point in time. See ``Commitment``.
    ///   

    public struct GetMinBalanceForRentExemptionConfiguration: Encodable {
        let commitment: Commitment?

        public init(
            commitment: Commitment? = nil
        ) {
            self.commitment = commitment
        }
    }

    /// Returns minimum balance required to make account rent exempt.
    ///
    /// This method sends a `getMinBalanceForRentExemption` RPC request to the Solana network. You can optionally provide a
    /// ``GetMinBalanceForRentExemptionConfiguration`` to control things like the commitment level.
    ///
    /// - Parameters:
    ///   - accountDataLength: An integer value to indicate the account's data length.
    ///   - configuration: Optional configuration for the request, such as
    ///                    commitment level and minimum context slot. Defaults to `nil`. See ``GetMinBalanceForRentExemptionConfiguration``
    ///
    /// - Returns: The minimum lamports required in the Account to remain rent free
    ///
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
