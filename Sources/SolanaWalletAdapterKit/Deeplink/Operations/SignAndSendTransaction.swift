import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC
import SolanaTransactions

extension DeeplinkWallet {
    /// Sign and send a transaction.
    public func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions? = nil)
        async throws -> SignAndSendTransactionResponseData
    {
        let connection = try _activeConnection

        let encodedTransaction = try transaction.encode().base58EncodedString()
        let payload = try SignAndSendTransactionRequestPayload(
            transaction: encodedTransaction,
            sendOptions: sendOptions,
            session: connection.session)

        return try await performSigningCall(
            endpoint: "signAndSendTransaction",
            payload: payload
        )
    }
}
