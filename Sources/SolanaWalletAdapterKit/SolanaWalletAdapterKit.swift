//import SolanaKit
//import CryptoKit
//
//public func hello() -> String {
//    let privateKey = Curve25519.Signing.PrivateKey()
//    let publicKey = privateKey.publicKey
//    
//    let solanaKey = SolanaPublicKey(bytes: ByteArrayKt.toByteArray(publicKey.rawRepresentation))
//    return solanaKey.address
//}
//
//public func test() async {
//    // Setup RPC driver
//    let rpcUrl = "https://api.endpoint.com"
//    let rpcDriver = RpccoreRpc20Driver(url: rpcUrl, httpDriver: NetworkDriver())
//    
//    // Build RPC request
//    let requestId = UUID().uuidString
//    let requestMethod = "getTheThing"
//    let rpcRequest = RpccoreJsonRpc20Request(method: requestMethod, params: nil, id: requestId)
//    
//    // Send the request and get response
//    let rpcResponse = try? await rpcDriver.makeRequest(
//        request: rpcRequest,
//        resultSerializer: Kotlinx_serialization_jsonJsonElement.companion.serializer()
//    )
//}
