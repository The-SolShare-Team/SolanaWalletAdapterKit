import SolanaTransactions

public enum ConfirmationStatus: String, Decodable {
    case processed
    case confirmed
    case finalized
}

public struct TransactionStatus: Decodable {
    public let confirmationStatus: ConfirmationStatus?
}



public struct SignatureStatusInfo: Decodable {
    public let slot: UInt64
    public let confirmations: UInt?
    public let err: JSONValue?
    public let status: TransactionStatus?
}

struct SignatureStatusesConfig: Encodable {
    let searchTransactionHistory: Bool
}

extension SolanaRPCClient {
    public func getSignatureStatuses(
        signatures: [String],
        searchTransactionHistory: Bool = false
    )
        async throws(RPCError) -> [SignatureStatusInfo?]
    {
        
        
        let response = try await fetch(
            method: "getSignatureStatuses",
            params: [
                signatures,
                SignatureStatusesConfig(searchTransactionHistory: searchTransactionHistory)
            ],
            into: RPCResponseResult<[SignatureStatusInfo?]>.self)
        print(response)
        return response.value
    }
}
