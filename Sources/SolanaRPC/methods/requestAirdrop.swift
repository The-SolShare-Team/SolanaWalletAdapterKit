import Foundation
import SolanaTransactions
import SwiftBorsh

extension SolanaRPCClient {
    public struct RequestAirdropConfiguration: Encodable {
        let commitment: Commitment?

        public init(
            commitment: Commitment? = nil
        ) {
            self.commitment = commitment
        }
    }

    /// https://solana.com/docs/rpc/http/requestairdrop
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
