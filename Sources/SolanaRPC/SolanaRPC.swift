import Foundation
import SwiftBorsh

struct RPCRequest: Encodable {
    let jsonrpc: String = "2.0"
    let id: Int
    let method: String
    let params: [Encodable]

    private enum CodingKeys: CodingKey {
        case jsonrpc
        case id
        case method
        case params
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)

        var paramsContainer = container.nestedUnkeyedContainer(forKey: .params)
        for param in params {
            try paramsContainer.encode(param)
        }
    }
}

struct RPCResponse<T: Decodable, E: Decodable>: Decodable {
    let jsonrpc: String
    let id: Int
    let result: T?
    let error: RPCError<E>?
}

struct RPCError<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T?
}

enum Commitment: Codable {
    case processed
    case confirmed
    case finalized
}

func getLatestBlockHash(commitment: Commitment, minContextSlot: Int) -> (
    blockhash: String, lastValidBlockHeight: UInt64
) {
    let request = RPCRequest(
        id: 1,
        method: "getLatestBlockhash",
        params: [
            commitment,
            minContextSlot,
        ]
    )

    struct ResponseData: Decodable {
        let blockhash: String
        let lastValidBlockHeight: UInt64
    }

    // Send request

    // let response = RPCResponse

    return ("hello", 13)
}
