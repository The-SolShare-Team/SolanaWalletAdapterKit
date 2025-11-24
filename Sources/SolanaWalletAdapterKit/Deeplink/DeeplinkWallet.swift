import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC
import SolanaTransactions

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

public struct DeeplinkWalletOptions: Sendable {
    public let baseURL: URL
    public let checkAvailableURL: URL?
    public let walletEncryptionPublicKeyIdentifier: String
    public let callbackParameter: String

    public init(
        baseURL: URL,
        checkAvailableURL: URL?,
        walletEncryptionPublicKeyIdentifier: String,
        callbackParameter: String = "redirect_link"
    ) {
        self.baseURL = baseURL
        self.checkAvailableURL = checkAvailableURL
        self.walletEncryptionPublicKeyIdentifier = walletEncryptionPublicKeyIdentifier
        self.callbackParameter = callbackParameter
    }
}

public protocol DeeplinkWallet: Wallet {
    static var _deeplinkWalletOptions: DeeplinkWalletOptions { get }
    var connection: DeeplinkWalletConnection? { get set }
}

extension DeeplinkWallet {
    var _activeConnection: DeeplinkWalletConnection {
        get throws {
            guard let connection else {
                throw SolanaWalletAdapterError.notConnected
            }
            return connection
        }
    }

    public static func isProbablyAvailable() -> Bool {
        guard let checkAvailableURL = Self._deeplinkWalletOptions.checkAvailableURL else {
            return false
        }
        #if os(iOS)
            return UIApplication.shared.canOpenURL(checkAvailableURL)
        #elseif os(macOS)
            return NSWorkspace.shared.urlForApplication(toOpen: checkAvailableURL)
                != nil
        #endif
    }

    // ***********************************
    // Utility functions
    // ***********************************

    /// Perform a signing call (e.g. signAndSendTransaction, signAllTransactions, etc.)
    /// - Parameters:
    ///     - endpointUrl: The endpoint URL
    ///     - payload: The encodable payload
    /// - Returns: The generated deeplink URL
    func performSigningCall<Request: Encodable, Response: Decodable>(
        endpoint: String, payload: Request
    ) async throws -> Response {
        // Request
        let endpointURL = Self._deeplinkWalletOptions.baseURL.appendingPathComponent(endpoint)
        let deeplink = try generateNonConnectDeeplinkURL(
            endpointUrl: endpointURL,
            payload: payload
        )

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link"
        )
        try throwIfErrorResponse(response: response)
        guard let nonce = response["payload"],
            let data = response["data"],
            let decodedNonce = Data(base58Encoded: nonce),
            let decodedData = Data(base58Encoded: data)
        else {
            throw SolanaWalletAdapterError.invalidResponse(response: response)
        }
        return try decryptPayload(
            encryptedData: decodedData,
            nonce: decodedNonce)
    }

    /// Generate a deeplink URL for non-connect methods. This is due to the fact that
    /// all methods other than connect have the same parameters.
    /// - Parameters:
    ///     - endpointUrl: The endpoint URL
    ///     - payload: The encodable payload
    /// - Returns: The generated deeplink URL
    func generateNonConnectDeeplinkURL<Payload: Encodable>(endpointUrl: URL, payload: Payload)
        throws -> URL
    {
        let connection = try _activeConnection

        let nonce = try SaltUtil.generateNonce()
        let encryptedPayload = try encryptPayload(
            payload: payload,
            nonce: nonce)

        var components = URLComponents(url: endpointUrl, resolvingAgainstBaseURL: false)!  // TODO: Can I force here?
        let queryItems = [
            URLQueryItem(
                name: "dapp_encryption_public_key",
                value: connection.encryption.publicKey.base58EncodedString()),
            URLQueryItem(name: "nonce", value: nonce.base58EncodedString()),
            URLQueryItem(name: "payload", value: encryptedPayload.base58EncodedString()),
        ]
        components.queryItems = queryItems

        return components.url!  // TODO: Can I force here?
    }

    /// Throws if the response is an error
    func throwIfErrorResponse(response: [String: String]) throws {
        if let errorCode = response["errorCode"],
            let errorMessage = response["errorMessage"]
        {
            guard let errorCode = Int(errorCode) else {
                throw SolanaWalletAdapterError.invalidResponse(response: response)
            }
            throw SolanaWalletAdapterError(walletErrorCode: errorCode, message: errorMessage)
        }
    }

    /// Decrypt the encrypted payload into the specified type
    /// If a sharedKey is not provided, the connection.encryption.sharedKey is used
    func decryptPayload<T: Decodable>(encryptedData: Data, nonce: Data, sharedKey: Data? = nil)
        throws -> T
    {
        // Decrypt the message
        let data = try SaltSecretBox.open(
            box: encryptedData,
            nonce: nonce,
            key: sharedKey ?? (try _activeConnection).encryption.sharedKey)

        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Encrypt the payload dictionary
    func encryptPayload<T: Encodable>(payload: T, nonce: Data) throws -> Data {
        let connection = try _activeConnection

        let payloadJson = try JSONEncoder().encode(payload)
        let encryptedPayload = try SaltSecretBox.secretBox(
            message: payloadJson,
            nonce: nonce,
            key: connection.encryption.sharedKey
        )

        return encryptedPayload
    }
}
