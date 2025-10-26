private struct RequestConfiguration: Encodable {
    let commitment: Commitment
    let minContextSlot: Int
}

private struct ResponseData: Decodable {
    let blockhash: String
    let lastValidBlockHeight: UInt64
}

extension SolanaRPCClient {
    public func getLatestBlockhash(
        configuration: (commitment: Commitment, minContextSlot: Int)? = nil
    )
        async throws(RPCError) -> (
            blockhash: String, lastValidBlockHeight: UInt64
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
