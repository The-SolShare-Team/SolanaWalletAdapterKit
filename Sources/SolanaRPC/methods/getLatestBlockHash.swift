import SolanaTransactions

extension SolanaRPCClient {
    /// Configuration options for the ``getLatestBlockhash(configuration:)`` RPC request.
    ///
    /// This struct allows you to provide **optional parameters** when requesting
    /// the latest blockhash from the Solana blockchain. All properties are optional,
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
    ///   - commitment: The commitment describes how finalized a block is at that point in time. See ``Commitment``.
    ///   - minContextSlot: The minimum slot that the request can be evaluated at.`.
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

    /// Response returned from the `getLatestBlockhash` RPC request to the Solana network.
    ///
    /// Use this struct to access the details of the latest blockhash when querying the network.
    ///
    /// - Properties:
    ///   - blockhash: The most recent blockhash on the network. This is typically used
    ///                when constructing transactions to ensure they are valid.
    ///   - lastValidBlockHeight: The last block height at which the returned blockhash
    ///                           remains valid. Transactions referencing this blockhash
    ///                           must be submitted before this height to be accepted.
    public struct GetLatestBlockhashResponse: Decodable {
        public let blockhash: Blockhash
        public let lastValidBlockHeight: UInt64
    }

    /// Returns the latest blockhash
    ///
    /// This method sends a `getLatestBlockhash` RPC request to the Solana network. You can optionally provide a
    /// ``GetLatestBlockhashConfiguration`` to control things like the commitment level or the minimum context slot.
    ///
    /// - Parameters:
    ///   - configuration: Optional configuration for the request, such as
    ///                    commitment level and minimum context slot. Defaults to `nil`. See ``GetLatestBlockhashConfiguration``
    ///
    /// - Returns: The blockhash and lastValidBlockHeight in the struct, ``GetLatestBlockhashResponse``
    ///
    /// - Throws: `RPCError` if the request fails or the response is invalid.
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
