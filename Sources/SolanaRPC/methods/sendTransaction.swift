import SolanaWalletAdapterKit

private struct RequestConfiguration: Encodable {
    let encoding: String
    let sendOptions: SendOptions
}


extension SolanaRPCClient {
    public func sendTransaction() async throws(RPCError) -> String {
        let response = try await fetch(
            method: "getVersion",
            params: [],
            into: ResponseData.self)
        return (response.solanaCore, response.featureSet)
    }
}
    
