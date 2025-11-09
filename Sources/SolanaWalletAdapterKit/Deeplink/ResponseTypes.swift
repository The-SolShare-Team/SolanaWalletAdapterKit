public struct ConnectResponseData: Decodable {
    public let publicKey: String
    public let session: String

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case session
    }
}

public struct SignAndSendTransactionResponseData: Decodable {
    public let signature: String
}

public struct SignAllTransactionsResponseData: Decodable {
    public let transactions: [String]
}

public struct SignTransactionResponseData: Decodable {
    public let transaction: String
}

public struct SignMessageResponseData: Decodable {
    public let signature: String
}
