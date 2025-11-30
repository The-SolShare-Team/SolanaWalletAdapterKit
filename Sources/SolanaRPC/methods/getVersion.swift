extension SolanaRPCClient {
    
    /// Response returned from the ``getVersion()`` RPC request to the Solana network.
    ///
    /// Use this struct to access the details of the version when querying the network.
    ///
    /// - Properties:
    ///   - solanaCore: The software version of `solana-core`.
    ///   - featureSet: A unique identifier of the current software's feature set.
    public struct GetVersionResponse: Decodable {
        public let solanaCore: String
        public let featureSet: UInt32

        enum CodingKeys: String, CodingKey {
            case solanaCore = "solana-core"
            case featureSet = "feature-set"
        }
    }

    /// Returns the current Solana version running on the node.
    ///
    /// This method queries the Solana RPC node and returns the version of
    /// `solana-core` and the feature set identifier of the current software.
    ///
    /// - Returns: A ``GetVersionResponse`` containing:
    ///   - `solanaCore`: The software version of `solana-core`.
    ///   - `featureSet`: A unique identifier of the current software's feature set.
    ///
    /// - Throws: `RPCError` if the request fails or the response is invalid.
    ///
    /// Example of `GetVersionResponse`:
    /// ```swift
    /// public struct GetVersionResponse: Decodable {
    ///     public let solanaCore: String
    ///     public let featureSet: UInt32
    ///
    ///     enum CodingKeys: String, CodingKey {
    ///         case solanaCore = "solana-core"
    ///         case featureSet = "feature-set"
    ///     }
    /// }
    /// ```
    public func getVersion() async throws(RPCError) -> GetVersionResponse {
        try await fetch(
            method: "getVersion",
            params: [],
            into: GetVersionResponse.self)
    }
}
