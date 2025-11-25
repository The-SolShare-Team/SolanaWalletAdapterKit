//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-11-23.
//

import SolanaTransactions

private struct RequestConfiguration: Encodable {
    let commitment: Commitment
    let maxSupportedTransactionVersion: Int = 0
    let encoding: String
}

private struct getTransactionResponse: Decodable {
    let blockTime: Int64?
    let meta: JSONValue?
    let slot: UInt64
    let transaction: JSONValue
    let version: TransactionVersion?
}

public enum TransactionVersion: Decodable {
    case legacy
    case v0(UInt64)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // If null → return nil (handled by optional)
        if container.decodeNil() {
            throw DecodingError.valueNotFound(TransactionVersion.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Transaction version is null"))
        }
        
        // If string and equals "legacy"
        if let string = try? container.decode(String.self), string == "legacy" {
            self = .legacy
            return
        }
        
        // If number → v0
        if let number = try? container.decode(UInt64.self) {
            self = .v0(number)
            return
        }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid transaction version")
    }
}


extension SolanaRPCClient {
    public func getTransaction(
        signature: String,
        configuration: (commitment: Commitment, encoding: String)? = nil
    )
    async throws -> (
        slot: UInt64?,
        blockTime: Int64?,
        meta: JSONValue?,
        transaction: JSONValue?,
        version: TransactionVersion?
    )
    {
        let response = try await fetchRaw(
            method: "getTransaction",
            params: [
                signature,
                configuration.map {
                    RequestConfiguration(
                        commitment: $0.commitment,
                        encoding: $0.encoding
                    )
                }
            ],
            into: RPCResponse<getTransactionResponse, String>.self
        )
        print(response)
        
        return (
            slot: response.result?.slot,
            blockTime: response.result?.blockTime,
            meta: response.result?.meta,
            transaction: response.result?.transaction,
            version: response.result?.version
        )
    }
}
