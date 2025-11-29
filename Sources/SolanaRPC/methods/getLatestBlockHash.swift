import SolanaTransactions

extension SolanaRPCClient {
    public struct GetLatestBlockhashConfiguration: Encodable {
        let commitment: Commitment?
        let minContextSlot: Int?

        public init(
            commitment: Commitment? = nil,
            minContextSlot: Int? = nil
        ) {
            self.commitment = commitment
            self.minContextSlot = minContextSlot
        }
    }

    public struct GetLatestBlockhashResponse: Decodable {
        public let blockhash: Blockhash
        public let lastValidBlockHeight: UInt64
    }

    /// https://solana.com/docs/rpc/http/getlatestblockhash
    public func getLatestBlockhash(
        configuration: GetLatestBlockhashConfiguration? = nil
    ) async throws(RPCError) -> GetLatestBlockhashResponse {
        var params: [Encodable] = []
        if let configuration {
            params.append(configuration)
        }

        return try await fetch(
            method: "getLatestBlockhash",
            params: params,
            into: RPCResponseResult<GetLatestBlockhashResponse>.self
        ).value
    }
}
