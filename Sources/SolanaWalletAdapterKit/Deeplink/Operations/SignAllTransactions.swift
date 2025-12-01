import Foundation
import SolanaTransactions

extension DeeplinkWallet {
    
    ///Signs all transactions that are provided to the wallet provider.
    ///
    /// - Parameters:
    ///   - transactions:An array of transaction that is to be signed by the wallet provider.
    ///- Returns: Payload in the form of ``SignAllTransactionsResponseData``, containing all the transactions that were signed from the payload after decription.
    ///
    ///See ``SignAllTransactionsResponseData`` for more details on the payload.
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
