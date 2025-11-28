import Base58
import Foundation
import SolanaTransactions

public struct ConnectResponseData: Decodable {
    public let publicKey: PublicKey
    public let session: String

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case session
    }
}

public struct SignAndSendTransactionResponseData: Decodable, Sendable {
    public let signature: Signature

    public init(signature: Signature) {
        self.signature = signature
    }
}

public struct SignAllTransactionsResponseData: Decodable, Sendable {
    public let transactions: [Transaction]

    public init(transactions: [Transaction]) {
        self.transactions = transactions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let strings: [String] = try container.decode([String].self, forKey: .transactions)
        var transactions: [Transaction] = []
        transactions.reserveCapacity(strings.count)
        for string in strings {
            guard let data = Data(base58Encoded: string) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .transactions, in: container,
                    debugDescription: "Invalid Base58 string: \(string)")
            }
            transactions.append(try Transaction(bytes: data))
        }
        self.transactions = transactions
    }

    private enum CodingKeys: CodingKey {
        case transactions
    }
}

public struct SignTransactionResponseData: Decodable, Sendable {
    public let transaction: Transaction

    public init(transaction: Transaction) {
        self.transaction = transaction
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let string: String = try container.decode(String.self, forKey: .transaction)
        guard let data = Data(base58Encoded: string) else {
            throw DecodingError.dataCorruptedError(
                forKey: .transaction, in: container,
                debugDescription: "Invalid Base58 string: \(string)")
        }
        self.transaction = try Transaction(bytes: data)
    }

    private enum CodingKeys: CodingKey {
        case transaction
    }
}

public struct SignMessageResponseData: Decodable, Sendable {
    public let signature: Signature
}
