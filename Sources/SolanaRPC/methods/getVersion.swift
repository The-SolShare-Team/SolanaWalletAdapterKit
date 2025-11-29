extension SolanaRPCClient {
    public struct GetVersionResponse: Decodable {
        public let solanaCore: String
        public let featureSet: UInt32

        enum CodingKeys: String, CodingKey {
            case solanaCore = "solana-core"
            case featureSet = "feature-set"
        }
    }

    /// https://solana.com/docs/rpc/http/getversion
    public func getVersion() async throws(RPCError) -> GetVersionResponse {
        try await fetch(
            method: "getVersion",
            params: [],
            into: GetVersionResponse.self)
    }
}
