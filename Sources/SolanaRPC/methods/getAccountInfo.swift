import Foundation
import SolanaTransactions
import SwiftBorsh

public enum AccountData: Codable {
    case string(String)
    case encoded([String])
    case object([String: String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([String].self) {
            self = .encoded(arrayValue)
        } else if let objectValue = try? container.decode([String: String].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid AccountData format"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .encoded(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        }
    }
}

extension SolanaRPCClient {
    public struct GetAccountInfoConfiguration: Encodable {
        let commitment: Commitment?
        let encoding: TransactionEncoding?
        let dataSlice: DataSlice?
        let minContextSlot: UInt64?
    }

    public struct DataSlice: Encodable {
        let offset: UInt64
        let length: UInt64
    }

    public struct GetAccountInfoResponse: Decodable {
        let data: AccountData
        let executable: Bool
        let lamports: UInt64
        let owner: String
        let rentEpoch: UInt64
        let space: UInt64
    }

    /// https://solana.com/docs/rpc/http/getaccountinfo
    public func getAccountInfo(
        account: PublicKey,
        configuration: GetAccountInfoConfiguration? = nil
    ) async throws(RPCError) -> GetAccountInfoResponse {
        var params: [Encodable] = [account]
        if let configuration {
            params.append(configuration)
        }

        return try await fetch(
            method: "getAccountInfo",
            params: params,
            into: RPCResponseResult<GetAccountInfoResponse>.self
        ).value
    }
}
