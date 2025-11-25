import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC
import SolanaTransactions

extension DeeplinkWallet {
    public mutating func connect() async throws -> DeeplinkWalletConnection? {
        guard connection == nil else { throw SolanaWalletAdapterError.alreadyConnected }

        let encryptionKeyPair = try SaltBox.keyPair()
        let deeplink = {
            let endpointURL = Self._deeplinkWalletOptions.baseURL.appendingPathComponent("connect")
            var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false)!
            let queryItems = [
                URLQueryItem(name: "app_url", value: appId.url.absoluteString),
                URLQueryItem(
                    name: "dapp_encryption_public_key",
                    value: encryptionKeyPair.publicKey.base58EncodedString()),
                URLQueryItem(name: "cluster", value: cluster.description),
            ]
            components.queryItems = queryItems
            return components.url!
        }()

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        try throwIfErrorResponse(response: response)
        guard
            let walletEncryptionPublicKey = response[
                Self._deeplinkWalletOptions.walletEncryptionPublicKeyIdentifier],
            let nonce = response["nonce"],
            let data = response["data"],
            let decodedWalletEncryptionPublicKey = Data(base58Encoded: walletEncryptionPublicKey),
            let decodedNonce = Data(base58Encoded: nonce),
            let decodedData = Data(base58Encoded: data)
        else {
            throw SolanaWalletAdapterError.invalidResponseFormat(response: response)
        }

        // Decrypt the data in the response
        let sharedSecretKey = try SaltBox.before(
            publicKey: decodedWalletEncryptionPublicKey,
            secretKey: encryptionKeyPair.secretKey)
        let decryptedData: ConnectResponseData = try decryptPayload(
            encryptedData: decodedData,
            nonce: decodedNonce,
            sharedKey: sharedSecretKey)

        let newConnection = DeeplinkWalletConnection(
            session: decryptedData.session,
            encryption: DeeplinkWalletConnection.DiffieHellmanData(
                publicKey: encryptionKeyPair.publicKey,
                privateKey: encryptionKeyPair.secretKey,
                sharedKey: sharedSecretKey),
            walletPublicKey: decryptedData.publicKey)

        self.connection = newConnection
        return newConnection
    }
}
