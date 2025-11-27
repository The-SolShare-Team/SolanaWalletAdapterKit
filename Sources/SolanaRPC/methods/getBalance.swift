import SolanaTransactions

private struct RequestConfiguration: Encodable {
    let commitment: Commitment
    let minContextSlot: Int
}



extension SolanaRPCClient {
    public func getBalance(
        publicKey: String,
        configuration: (commitment: Commitment, minContextSlot: Int)? = nil
    )
    async throws(RPCError) -> UInt64
    {
        let response = try await fetch(
            method: "getBalance",
            params: [
                publicKey,
                configuration.map {
                    RequestConfiguration(
                        commitment: $0.commitment,
                        minContextSlot: $0.minContextSlot
                    )
                }
            ],
            into: RPCResponseResult<UInt64>.self)
        return response.value
    }
}