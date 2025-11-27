import Base58
import CryptoKit
import Foundation
import Security
import SimpleKeychain
import SolanaTransactions

extension DeeplinkWallet {
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
