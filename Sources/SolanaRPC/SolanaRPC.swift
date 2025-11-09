import Foundation
import SwiftBorsh

struct RPCRequest: Encodable {
    let jsonrpc: String = "2.0"
    let id = UUID().uuidString
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
    let id: String
    let result: T?
    let error: RPCResponseError<E>?
}

struct RPCResponseError<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T?
}

struct RPCResponseContext: Decodable {
    let slot: UInt64
    let apiVersion: String?
}

struct RPCResponseResult<T: Decodable>: Decodable {
    let context: RPCResponseContext
    let value: T
}

public struct RPCError: Error, CustomStringConvertible {
    public let message: String
    public let kind: Kind
    public let data: Sendable?

    public enum Kind: Sendable, CustomStringConvertible {
        case clientError

        case parseError
        case invalidRequest
        case methodNotFound
        case invalidParams
        case internalError
        case serverError
        case unknown(code: Int)

        public init(code: Int) {
            switch code {
            case -32700:
                self = .parseError
            case -32600:
                self = .invalidRequest
            case -32601:
                self = .methodNotFound
            case -32602:
                self = .invalidParams
            case -32603:
                self = .internalError
            case -32000 ... -32099:
                self = .serverError
            default:
                self = .unknown(code: code)
            }
        }

        public var description: String {
            switch self {
            case .clientError:
                return "Client Error"
            case .parseError:
                return "Parse Error"
            case .invalidRequest:
                return "Invalid Request"
            case .methodNotFound:
                return "Method Not Found"
            case .invalidParams:
                return "Invalid Params"
            case .internalError:
                return "Internal Error"
            case .serverError:
                return "Server Error"
            case .unknown(let code):
                return "Unknown Error (code \(code))"
            }
        }
    }

    public var description: String {
        let label: String = kind.description
        if let data = data {
            return "\(label): \(message), \(String(describing: data))"
        } else {
            return "\(label): \(message)"
        }
    }
}

public enum Endpoint: Sendable {
    case mainnet
    case testnet
    case devnet
    case other(url: URL)

    public var url: URL {
        switch self {
        case .mainnet:
            return URL(string: "https://api.mainnet-beta.solana.com")!
        case .testnet:
            return URL(string: "https://api.testnet.solana.com")!
        case .devnet:
            return URL(string: "https://api.devnet.solana.com")!
        case .other(let url):
            return url
        }
    }

    public var name: String {
        switch self {
        case .mainnet:
            return "mainnet"
        case .testnet:
            return "testnet"
        case .devnet:
            return "devnet"
        case .other:  // TODO: Solflare does not support otehr though
            return "other"
        }
    }
}

public enum Commitment: Codable {
    case processed
    case confirmed
    case finalized
}

public struct SolanaRPCClient {
    public let endpoint: Endpoint

    public init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }

    func fetch<T: Decodable>(method: String, params: [Encodable], into: T.Type)
        async
        throws(RPCError) -> T
    {
        let request = RPCRequest(
            method: method,
            params: params
        )

        var urlRequest = URLRequest(url: endpoint.url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw RPCError(
                message: "Encoding error",
                kind: .clientError,
                data: error
            )
        }

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            throw RPCError(
                message: "Network error",
                kind: .clientError,
                data: error
            )
        }

        let response: RPCResponse<T, String>
        do {
            response = try JSONDecoder().decode(RPCResponse<T, String>.self, from: data)
        } catch {
            throw RPCError(
                message: "Decoding error",
                kind: .clientError,
                data: error
            )
        }

        if response.id != request.id {
            throw RPCError(
                message: "Decoding error",
                kind: .clientError,
                data: "Response ID does not match Request ID"
            )
        }

        if response.jsonrpc != "2.0" {
            throw RPCError(
                message: "Decoding error",
                kind: .clientError,
                data: "Unsupported JSON-RPC version: \(response.jsonrpc)"
            )
        }

        if let error = response.error {
            throw RPCError(
                message: error.message,
                kind: .init(code: error.code),
                data: error.data
            )
        }

        guard let result = response.result else {
            throw RPCError(
                message: "Decoding error",
                kind: .clientError,
                data: "No result in response"
            )
        }

        return result
    }
}
