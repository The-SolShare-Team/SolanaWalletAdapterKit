import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC
import SolanaTransactions

extension DeeplinkWallet {
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
