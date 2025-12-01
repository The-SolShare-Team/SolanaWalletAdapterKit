import Base58
import CryptoKit
import Foundation
import Security
import SimpleKeychain
import SolanaTransactions

extension DeeplinkWallet {
    
    ///Signs a transactions that is provided to the wallet provider.
    ///
    /// - Parameters:
    ///   - transaction:The transaction that is to be signed by the wallet provider.
    ///- Returns: Payload in the form of ``SignTransactionResponseData``, containing the transaction that was signed from the payload after decryption.
    ///
    ///See ``SignTransactionResponseData`` for more details on the payload.
    public func signTransaction(transaction: Transaction)
        async throws -> SignTransactionResponseData
    {
        let connection = try _activeConnection

        let encodedTransaction = try transaction.encode().base58EncodedString()
        let payload = SignTransactionRequestPayload(
            transaction: encodedTransaction,
            session: connection.session)

        return try await performSigningCall(
            endpoint: "signTransaction",
            payload: payload
        )
    }
}
