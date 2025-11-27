import SolanaTransactions

extension SolanaRPCClient {
    public struct GetBalanceConfiguration: Encodable {
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

    public func getBalance(
        account: PublicKey,
        configuration: GetBalanceConfiguration? = nil
    )
        async throws(RPCError) -> UInt64
    {
        var params: [Encodable] = [account]
        if let configuration {
            params.append(configuration)
        }

        return try await fetch(
            method: "getBalance",
            params: params,
            into: RPCResponseResult<UInt64>.self
        ).value
    }
}
