import SolanaTransactions

private struct RequestConfiguration: Encodable {
    let commitment: Commitment?
    let minContextSlot: Int?
}

private struct ResponseData: Decodable {
    let blockhash: Blockhash
    let lastValidBlockHeight: UInt64
}

extension SolanaRPCClient {
    public func getLatestBlockhash(
        configuration: (commitment: Commitment?, minContextSlot: Int?)? = nil
    )
        async throws(RPCError) -> (
            blockhash: Blockhash, lastValidBlockHeight: UInt64
        )
    {
        var params: [Encodable] = []

        if let configuration = configuration {
            params.append(
                RequestConfiguration(
                    commitment: configuration.commitment,
                    minContextSlot: configuration.minContextSlot
                ))
        }

        let response = try await fetch(
            method: "getLatestBlockhash",
            params: params,
            into: RPCResponseResult<ResponseData>.self)
        return (response.value.blockhash, response.value.lastValidBlockHeight)
    }
}
