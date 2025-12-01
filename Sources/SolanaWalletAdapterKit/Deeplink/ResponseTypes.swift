import Base58
import Foundation
import SolanaTransactions

/// Response data returned when a wallet connection is successfully established.
///
/// Use this struct when calling ``DeeplinkWallet/connect()`` to capture the
/// wallet's public key and session information for encrypted communication.
public struct ConnectResponseData: Decodable {
    public let publicKey: PublicKey
    public let session: String

    enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
        case session
    }
}

/// Response data returned when a transaction is signed by the deeplink wallet
/// and sent to the Solana network.
///
/// Use this struct when calling
/// ``DeeplinkWallet/signAndSendTransaction(transaction:sendOptions:)``
/// to retrieve the resulting transaction signature.
public struct SignAndSendTransactionResponseData: Decodable, Sendable {
    public let signature: Signature

    public init(signature: Signature) {
        self.signature = signature
    }
}

/// Response data returned when multiple transactions are signed by a deeplink wallet.
///
/// Use this struct when calling
/// ``DeeplinkWallet/signAllTransactions(transactions:)``
/// to capture all signed transactions.
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

/// Response data returned when a single transaction is signed by the deeplink wallet.
///
/// Use this struct when calling
/// ``DeeplinkWallet/signTransaction(transaction:)`` to capture the signed transaction.
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

/// Response data returned when a message is signed by the deeplink wallet.
///
/// Use this struct when calling ``DeeplinkWallet/signMessage(message:)``
/// to capture the resulting signature.
public struct SignMessageResponseData: Decodable, Sendable {
    public let signature: Signature
}
