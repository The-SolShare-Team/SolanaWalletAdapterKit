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
    ///   - commitment: The commitment level indicates how confirmed a block is at the time of the query. See ``Commitment``.
    public struct RequestAirdropConfiguration: Encodable {
        let commitment: Commitment?

        public init(
            commitment: Commitment? = nil
        ) {
            self.commitment = commitment
        }
    }
    
    /// See [requestAirdrop](https://solana.com/docs/rpc/http/requestairdrop) implementation on Solana Docs.
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
