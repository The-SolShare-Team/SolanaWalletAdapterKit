private struct ResponseData: Decodable {
    let solanaCore: String
    let featureSet: UInt32

    enum CodingKeys: String, CodingKey {
        case solanaCore = "solana-core"
        case featureSet = "feature-set"
    }
}

extension SolanaRPCClient {
    public func getVersion() async throws(RPCError) -> (
        solanaCore: String, featureSet: UInt32
    ) {
        let response = try await fetch(
            method: "getVersion",
            params: [],
            into: ResponseData.self)
        return (response.solanaCore, response.featureSet)
    }
}
