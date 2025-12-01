import Foundation
import SolanaTransactions

extension DeeplinkWallet {
    /// Signs and sends a transaction to the Solana blockchain through the Wallet Provider.
    ///
    /// In addition to requesting a signature from the wallet provider, this method
    /// also allows the wallet provider to submit the signed transaction, instead of sending it through the Solana RPC directly from the dApp.
    ///
    /// - Parameters:
    ///   - transaction:The transaction that is to be signed and sent to the Solana Network.
    ///   - sendOptions: Optional parameters to send to the wallet app. See ``SendOptions``.
    ///
    /// -  Returns: Payload in the form of ``SignAndSendTransactionResponseData``, containing all the transactions that were signed from the payload after decryption.
    ///
    /// See ``SignAndSendTransactionResponseData`` for more details on response.

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
