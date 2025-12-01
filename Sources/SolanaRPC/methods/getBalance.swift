import SolanaTransactions

extension SolanaRPCClient {
    /// Configuration options for the ``getBalance(account:configuration:)`` RPC request.
    ///
    /// This struct allows you to provide **optional parameters** when requesting
    /// an account's balance from the Solana blockchain. All properties are optional,
    /// so you can specify only the values you need.
    ///
    ///```
    ///public init(
    ///     commitment: Commitment? = nil
    ///     minContextSlot: Int? = nil
    ///) {
    ///     self.commitment = commitment
    ///     self.minContextSlot = minContextSlot
    /// }
    /// ```
    /// 
    /// - Parameters:
    ///   - commitment: The commitment level indicates how confirmed a block is at the time of the query. See ``Commitment``.
    ///   - minContextSlot: The lowest slot at which the request can be evaluated at.
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

    /// See [getBalance](https://solana.com/docs/rpc/http/getbalance) implementation on Solana Docs.
    ///
    /// This method sends a `getBalance` RPC request to the Solana network
    /// for the specified account. You can optionally provide a
    /// ``GetBalanceConfiguration`` to control things like the commitment
    /// level or the minimum context slot.
    ///
    /// - Throws: `RPCError` if the request fails or the response is invalid.
    public func getBalance(
        account: PublicKey,
        configuration: GetBalanceConfiguration? = nil
    ) async throws(RPCError) -> UInt64 {
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
