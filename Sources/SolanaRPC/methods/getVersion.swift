extension SolanaRPCClient {
    
    /// Response returned from the ``getVersion()`` RPC request to the Solana network.
    ///
    /// Use this struct to access the details of the version when querying the network.
    ///
    /// See [getVersion](https://solana.com/docs/rpc/http/getversion)  for optional properties.
    public struct GetVersionResponse: Decodable {
        public let solanaCore: String
        public let featureSet: UInt32

        enum CodingKeys: String, CodingKey {
            case solanaCore = "solana-core"
            case featureSet = "feature-set"
        }
    }

    /// See [getVersion](https://solana.com/docs/rpc/http/getversion) implementation on Solana Docs.
    ///
    public func getVersion() async throws(RPCError) -> GetVersionResponse {
        try await fetch(
            method: "getVersion",
            params: [],
            into: GetVersionResponse.self)
    }
}
