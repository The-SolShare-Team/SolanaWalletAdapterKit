import SolanaTransactions

private struct RequestConfiguration: Encodable {
    let commitment: Commitment
    let minContextSlot: Int
}

private struct ResponseData: Decodable {
    let blockhash: Blockhash
    let lastValidBlockHeight: UInt64
}

extension SolanaRPCClient {
    /// https://solana.com/docs/rpc/http/getlatestblockhash
    public func getLatestBlockhash(
        configuration: (commitment: Commitment, minContextSlot: Int)? = nil
    )
        async throws(RPCError) -> (
            blockhash: Blockhash, lastValidBlockHeight: UInt64
        )
    {
        let response = try await fetch(
            method: "getLatestBlockhash",
            params: [
                configuration.map {
                    RequestConfiguration(
                        commitment: $0.commitment,
                        minContextSlot: $0.minContextSlot
                    )
                }
            ],
            into: RPCResponseResult<ResponseData>.self)
        return (response.value.blockhash, response.value.lastValidBlockHeight)
    }
}
