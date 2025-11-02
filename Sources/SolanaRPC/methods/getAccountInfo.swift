import Foundation
import SolanaTransactions
import SwiftBorsh

public struct AccountInfoConfig: Codable, Equatable {
    public let commitment: Commitment?
    public let encoding: TransactionEncoding?
    public let dataSlice: DataSlice?
    public let minContextSlot: UInt64?

    public init(
        commitment: Commitment? = nil,
        encoding: TransactionEncoding? = nil,
        dataSlice: DataSlice? = nil,
        minContextSlot: UInt64? = nil
    ) {
        self.commitment = commitment
        self.encoding = encoding
        self.dataSlice = dataSlice
        self.minContextSlot = minContextSlot
    }
}

public struct DataSlice: Codable, Equatable {
    public let offset: UInt64
    public let length: UInt64
}

public struct AccountInfoResult: Codable, Equatable {
    public let data: AccountData
    public let executable: Bool
    public let lamports: UInt64
    public let owner: String
    public let rentEpoch: UInt64
    public let space: UInt64
}

public enum AccountData: Codable, Equatable {
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
                debugDescription: "Invalid data format for AccountData"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .encoded(let array): try container.encode(array)
        case .object(let dict): try container.encode(dict)
        }
    }
}


extension SolanaRPCClient {

    public func getAccountInfo(
        for account: PublicKey,
        config: AccountInfoConfig? = nil
    ) async throws -> AccountInfoResult? {
        let base58Address = try BorshEncoder.base58Encode(account)

        let response: RPCResponseResult<AccountInfoResult?> = try await fetch(
            method: "getAccountInfo",
            params: [base58Address, config ?? AccountInfoConfig()],
            into: RPCResponseResult<AccountInfoResult?>.self
        )

        return response.value
    }
}
