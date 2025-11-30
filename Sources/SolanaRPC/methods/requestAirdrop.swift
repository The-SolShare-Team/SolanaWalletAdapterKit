import Foundation
import SolanaTransactions
import SwiftBorsh

extension SolanaRPCClient {
    /// Configuration options for the ``requestAirdrop(to:lamports:configuration:)`` RPC request.
    ///
    /// This struct allows you to provide **optional parameters** when requesting an airdrop  from the Solana blockchain. All properties are optional,
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
    public struct RequestAirdropConfiguration: Encodable {
        let commitment: Commitment?

        public init(
            commitment: Commitment? = nil
        ) {
            self.commitment = commitment
        }
    }
    
    /// Requests an airdrop of lamports to a Pubkey
    ///
    /// This method sends a `getMinBalanceForRentExemption` RPC request to the Solana network. You can optionally provide a
    /// ``RequestAirdropConfiguration`` to control things like the commitment level.
    ///
    /// - Parameters:
    ///   - address: Pubkey of account to receive lamports, as a base-58 encoded string
    ///   - lamports: Amount of lamports to airdrop
    ///   - configuration: Optional configuration for the request, such as
    ///                    commitment level and minimum context slot. Defaults to `nil`. See ``RequestAirdropConfiguration``
    ///                    
    /// - Returns: Transaction Signature of the airdrop, as a base-58 encoded string
    ///
    /// - Throws: `RPCError` if the request fails or the response is invalid.
    @discardableResult
    public func requestAirdrop(
        to address: PublicKey,
        lamports: UInt64,
        configuration: RequestAirdropConfiguration? = nil
    ) async throws(RPCError) -> Signature {
        var params: [Encodable] = [address, lamports]
        if let configuration {
            params.append(configuration)
        }

        return try await fetch(
            method: "requestAirdrop",
            params: [address, lamports],
            into: Signature.self
        )
    }
}
