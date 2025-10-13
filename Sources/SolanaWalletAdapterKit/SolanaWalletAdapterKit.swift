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
        print(request.body, request.method, request.properties, request.url)
    }
}

public func test() async {
    let rpcUrl = "https://api.endpoint.com"
    let rpcDriver = RpccoreRpc20Driver(url: rpcUrl, httpDriver: RpcNetworkDriver())
    
    let requestId = UUID().uuidString
    let requestMethod = "getTheThing"
    
    let rpcRequest = RpccoreJsonRpc20Request(method: requestMethod, params: nil, id: requestId)
    try? await rpcDriver.makeRequest(request: rpcRequest, resultSerializer: Kotlinx_serialization_jsonJsonElement.companion.serializer())
}
