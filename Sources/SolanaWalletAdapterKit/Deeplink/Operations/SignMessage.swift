import Foundation

extension DeeplinkWallet {
    ///Signs a message that is provided to the method.
    ///
    /// - Parameters:
    ///   - message:An encoded message indicating the instructions of transaction. See ``SolanaTransactions`` for more details.
    ///   - display: An optional display format for the message. See ``MessageDisplayFormat`` for more details.
    ///
    ///- Returns: Payload in the form of ``SignMessageResponseData``, containing the message that was signed from the payload after decryption.
    ///
    ///See ``SignMessageResponseData`` for more details on the payload.
    public func signMessage(message: Data, display: MessageDisplayFormat? = nil)
        async throws -> SignMessageResponseData
    {
        let connection = try _activeConnection

        let encodedMessage = message.base58EncodedString()
        let payload = SignMessageRequestPayload(
            message: encodedMessage,
            session: connection.session,
            display: display)

        return try await performSigningCall(
            endpoint: "signMessage",
            payload: payload
        )
    }
}
