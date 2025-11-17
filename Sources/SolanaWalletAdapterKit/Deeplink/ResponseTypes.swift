public struct ConnectResponseData: Decodable {
    public let publicKey: String
    public let session: String

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case session
    }
}

public struct SignAndSendTransactionResponseData: Decodable, Sendable {
    public let signature: String
}

public struct SignAllTransactionsResponseData: Decodable, Sendable {
    public let transactions: [String]
}

public struct SignTransactionResponseData: Decodable, Sendable {
    public let transaction: String
}

public struct SignMessageResponseData: Decodable, Sendable {
    public let signature: String
}
