// The Swift Programming Language
// https://docs.swift.org/swift-book

import web3_solana
import rpc_solana
import CryptoKit

public func hello() -> String {
    let privateKey = Curve25519.Signing.PrivateKey()
    let publicKey = privateKey.publicKey
    
    let solanaKey = SolanaPublicKey(bytes: ByteArrayKt.toByteArray(publicKey.rawRepresentation))
    return solanaKey.address
}

class RpcNetworkDriver: RpccoreHttpNetworkDriver {
    func makeHttpRequest(request: RpccoreHttpRequest, completionHandler: @escaping @Sendable (String?, (any Error)?) -> Void) {
        print("**********************************")
        print("\nBody: ", request.body)
        print("\nMethod: ", request.method)
        print("\nProperties: ", request.properties)
        print("\nURL: ", request.url)
        print("**********************************")
    }
}

public func test() async {
    // Setup RPC driver
    let rpcUrl = "https://api.endpoint.com"
    let rpcDriver = RpccoreRpc20Driver(url: rpcUrl, httpDriver: RpcNetworkDriver())
    
    // Build RPC request
    let requestId = UUID().uuidString
    let requestMethod = "getTheThing"
    let rpcRequest = RpccoreJsonRpc20Request(method: requestMethod, params: nil, id: requestId)
    
    // Send the request and get response
    try? await rpcDriver.makeRequest(
        request: rpcRequest,
        resultSerializer: Kotlinx_serialization_jsonJsonElement.companion.serializer()
    )
}
