import Foundation
import SolanaTransactions

extension DeeplinkWallet {
    public func signAllTransactions(transactions: [Transaction])
        async throws -> SignAllTransactionsResponseData
    {
        let connection = try _activeConnection

        let encodedTransactions: [String] = try transactions.map {
            try $0.encode().base58EncodedString()
        }
        let payload = SignAllTransactionsRequestPayload(
            transactions: encodedTransactions,
            session: connection.session)

        return try await performSigningCall(
            endpoint: "signAllTransactions",
            payload: payload
        )
    }
}
