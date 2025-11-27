import Foundation
import SolanaTransactions
import SwiftBorsh

private struct AccountInfoConfig: Encodable {
     let commitment: Commitment?
     let encoding: TransactionEncoding?
     let dataSlice: DataSlice?
     let minContextSlot: UInt64?
}
private struct AccountInfoResult: Decodable {
    public let data: AccountData
    public let executable: Bool
    public let lamports: UInt64
    public let owner: String
    public let rentEpoch: UInt64
    public let space: UInt64
}
public struct DataSlice: Codable {
    public let offset: UInt64
    public let length: UInt64
}


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

// MARK: - getAccountInfo returning a tuple
extension SolanaRPCClient {
    public func getAccountInfo(
        for account: PublicKey,
        config: (commitment: Commitment, encoding: TransactionEncoding, dataSlice: DataSlice, minContextSlot: UInt64)? = nil
    )
        async throws(RPCError) -> (
            data: AccountData, executable: Bool, lamports: UInt64, owner: String, rentEpoch: UInt64, space: UInt64
        )
    {
        let response = try await fetch(
            method: "getAccountInfo",
            params: [
                config.map {
                    AccountInfoConfig(
                        commitment: $0.commitment,
                        encoding: $0.encoding,
                        dataSlice: $0.dataSlice,
                        minContextSlot: $0.minContextSlot,

                    )
                }
            ],

            into: RPCResponseResult<AccountInfoResult>.self)

        return (response.value.data, response.value.executable, response.value.lamports, response.value.owner, response.value.rentEpoch, response.value.space)

    }
}
