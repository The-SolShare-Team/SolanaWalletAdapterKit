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

public struct DiffieHellmanData: Codable {
    let publicKey: Data
    let privateKey: Data
    let sharedKey: Data

    public init(publicKey: Data, privateKey: Data, sharedKey: Data) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.sharedKey = sharedKey
    }
}

public struct WalletConnection: Codable {
    let encryption: DiffieHellmanData
    public let walletPublicKey: String
    let session: String  // TODO: Do the other fields also need to be public?

    public init(encryption: DiffieHellmanData, walletPublicKey: String, session: String) {
        self.encryption = encryption
        self.walletPublicKey = walletPublicKey
        self.session = session
    }
}

/// Protocol for Deeplink wallets.
/// Note: Only classes can conform to this protocol.
public protocol DeeplinkWallet: Wallet, AnyObject {
    static var baseURL: URL { get }
    var connection: WalletConnection? { get set }
    func pair(walletEncryptionPublicKeyIdentifier: String) async throws
}

extension DeeplinkWallet {
    var secureStorageKey: String { "\(appId.name)-\(appId.url.absoluteString)-\(cluster)" }

    /**
        Pair with the wallet.
    */
    public func pair(walletEncryptionPublicKeyIdentifier: String) async throws {
        guard connection == nil else { throw SolanaWalletAdapterError.alreadyConnected }

        let endpointUrl = Self.getEndpointUrl(path: "connect")

        let encryptionKeyPair = try SaltBox.keyPair()

        var components = URLComponents(url: endpointUrl, resolvingAgainstBaseURL: false)!  // TODO: Can I force here?
        let queryItems = [
            URLQueryItem(name: "app_url", value: appId.url.absoluteString),
            URLQueryItem(
                name: "dapp_encryption_public_key",
                value: encryptionKeyPair.publicKey.base58EncodedString()),
            URLQueryItem(name: "cluster", value: cluster.description),
        ]
        components.queryItems = queryItems
        let deeplink = components.url!  // TODO: Can I force here?

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        guard let walletEncryptionPublicKey = response[walletEncryptionPublicKeyIdentifier],
            let nonce = response["nonce"],
            let data = response["data"],
            let decodedWalletEncryptionPublicKey = Data(base58Encoded: walletEncryptionPublicKey),
            let decodedNonce = Data(base58Encoded: nonce),
            let decodedData = Data(base58Encoded: data)
        else {
            throw SolanaWalletAdapterError.invalidResponse
        }

        // Decrypt the data in the response
        let sharedSecretKey = try SaltBox.before(
            publicKey: Data(decodedWalletEncryptionPublicKey),
            secretKey: encryptionKeyPair.secretKey)
        let decryptedData: ConnectResponseData = try decryptPayload(
            encryptedData: Data(decodedData),
            nonce: Data(decodedNonce),
            sharedKey: sharedSecretKey)

        // Set the connection property on the wallet
        self.connection = WalletConnection(
            encryption: DiffieHellmanData(
                publicKey: encryptionKeyPair.publicKey,
                privateKey: encryptionKeyPair.secretKey,
                sharedKey: sharedSecretKey),
            walletPublicKey: decryptedData.publicKey,
            session: decryptedData.session)

        // We force unwrap here because connection is set just above.
        try await secureStorage.storeWalletConnection(
            self.connection!,
            key: self.secureStorageKey)
    }

    /**
        Unpair from the wallet.
    */
    public func unpair() async throws {
        checkIsConnected()

        let endpointUrl: URL = Self.getEndpointUrl(path: "disconnect")

        // Request
        let requestPayload: [String: Any] = [
            "session": connection!.session
        ]
        let deeplink = try generateNonConnectDeeplinkURL(
            endpointUrl: endpointUrl, payload: requestPayload)

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        try throwIfError(response: response)

        // Clear secure storage and reset connection
        try await secureStorage.clear(key: self.secureStorageKey)
        self.connection = nil
    }

    /**
        Sign and send a transaction.
    */
    public func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions? = nil)
        async throws -> SignAndSendTransactionResponseData
    {
        checkIsConnected()

        let endpointUrl = Self.getEndpointUrl(path: "signAndSendTransaction")

        // Request
        let encodedTransaction = try transaction.encode().base58EncodedString()
        var requestPayload: [String: Any] = [
            "transaction": encodedTransaction,
            "session": connection!.session,
        ]
        if let sendOptions {
            let sendOptionsJson = try JSONEncoder().encode(sendOptions)
            let encodedSendOptions = String(data: sendOptionsJson, encoding: .utf8) ?? ""  // TODO: Not sure if this is the right way to handle the optional here
            requestPayload["sendOptions"] = encodedSendOptions
        }
        let deeplink = try generateNonConnectDeeplinkURL(
            endpointUrl: endpointUrl, payload: requestPayload)

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        try throwIfError(response: response)
        return try processSigningMethodResponse(
            response: response)
    }

    /**
        Sign all transactions.
    */
    public func signAllTransactions(transactions: [Transaction])
        async throws -> SignAllTransactionsResponseData
    {
        checkIsConnected()

        let endpointUrl = Self.getEndpointUrl(path: "signAllTransactions")

        // Request
        let encodedTransactions: [String] = try transactions.map {
            try $0.encode().base58EncodedString()
        }
        let requestPayload: [String: Any] = [
            "transactions": encodedTransactions,
            "session": connection!.session,
        ]
        let deeplink = try generateNonConnectDeeplinkURL(
            endpointUrl: endpointUrl, payload: requestPayload)

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        try throwIfError(response: response)
        return try processSigningMethodResponse(
            response: response)
    }

    /**
        Sign a transaction.
    */
    public func signTransaction(transaction: Transaction)
        async throws -> SignTransactionResponseData
    {
        checkIsConnected()

        let endpointUrl = Self.getEndpointUrl(path: "signTransaction")

        // Request
        let encodedTransaction = try transaction.encode().base58EncodedString()
        let requestPayload: [String: Any] = [
            "transaction": encodedTransaction,
            "session": connection!.session,
        ]
        let deeplink = try generateNonConnectDeeplinkURL(
            endpointUrl: endpointUrl, payload: requestPayload)

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        try throwIfError(response: response)
        return try processSigningMethodResponse(
            response: response)
    }

    /**
        Sign a message.
    */
    public func signMessage(message: Data, display: DisplayFormat? = nil)
        async throws -> SignMessageResponseData
    {
        checkIsConnected()

        let endpointUrl = Self.getEndpointUrl(path: "signMessage")

        // Request
        let encodedMessage = message.base58EncodedString()
        var requestPayload: [String: Any] = [
            "message": encodedMessage,
            "session": connection!.session,
        ]
        if let display {
            requestPayload["display"] = display.rawValue
        }
        let deeplink = try generateNonConnectDeeplinkURL(
            endpointUrl: endpointUrl, payload: requestPayload)

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        try throwIfError(response: response)
        return try processSigningMethodResponse(
            response: response)
    }

    /**
        Browse to a URL.
    */
    public func browse(url: URL, ref: URL) async throws {
        let endpointUrl = Self.getEndpointUrl(path: "browse")

        guard
            let encodedTargetURL = url.absoluteString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let encodedRefURL = ref.absoluteString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed)
        else {
            throw SolanaWalletAdapterError.browsingFailed  // TODO: Is this a good error?
        }

        let deeplink = "\(endpointUrl)/\(encodedTargetURL)?ref=\(encodedRefURL)"
        if let deeplink = URL(string: deeplink) {
            // TODO: Not if this is how we should handle it
            #if os(iOS)
                let success = await UIApplication.shared.open(deeplink)
            #elseif os(macOS)
                let success = NSWorkspace.shared.open(deeplink)
            #endif
        } else {
            throw DeeplinkFetchingError.unableToOpen  // TODO: Not sure about this error
        }
    }

    // ***********************************
    // Utility functions
    // ***********************************

    /// Check if the wallet is connected, otherwise crash
    func checkIsConnected() {
        precondition(connection != nil, "Wallet is not connected.")
    }

    /// Get endpoint URL by appending path to baseURL
    static func getEndpointUrl(path: String) -> URL {
        if #available(iOS 16.0, macOS 13, *) {
            return Self.baseURL.appending(path: path, directoryHint: .notDirectory)
        } else {
            return Self.baseURL.appendingPathComponent(path)
        }
    }

    /// Throws if the response is an error
    func throwIfError(response: [String: String]) throws {
        if let errorCode = response["errorCode"],
            let errorMessage = response["errorMessage"]
        {
            guard let errorCode = Int(errorCode) else {
                throw SolanaWalletAdapterError.invalidResponse
            }
            throw WalletError(code: errorCode, message: errorMessage)
        }
    }

    /// Process response for signing methods.
    func processSigningMethodResponse<T: Decodable>(response: [String: String]) throws -> T {
        guard let nonce = response["payload"],
            let data = response["data"],
            let decodedNonce = Data(base58Encoded: nonce),
            let decodedData = Data(base58Encoded: data)
        else {
            throw SolanaWalletAdapterError.invalidResponse
        }
        return try decryptPayload(
            encryptedData: Data(decodedData),
            nonce: Data(decodedNonce))
    }

    /// Generate a deeplink URL for non-connect methods. This is due to the fact that
    /// all methods other than connect have the same parameters.
    /// - Parameters:
    ///     - endpointUrl: The endpoint URL
    ///     - payload: The unencrypted payload dictionary
    /// - Returns: The generated deeplink URL
    func generateNonConnectDeeplinkURL(endpointUrl: URL, payload: [String: Any]) throws -> URL {
        checkIsConnected()

        let nonce = try generateNonce()
        let encryptedPayload = try encryptPayload(
            payload: payload,
            nonce: nonce)

        var components = URLComponents(url: endpointUrl, resolvingAgainstBaseURL: false)!  // TODO: Can I force here?
        let queryItems = [
            URLQueryItem(
                name: "dapp_encryption_public_key",
                value: connection!.encryption.publicKey.base58EncodedString()),
            URLQueryItem(name: "nonce", value: nonce.base58EncodedString()),
            URLQueryItem(name: "payload", value: encryptedPayload.base58EncodedString()),
        ]
        components.queryItems = queryItems

        return components.url!  // TODO: Can I force here?
    }

    /// Decrypt the encrypted payload into the specified type
    /// If a sharedKey is not provided, the connection.encryption.sharedKey is used
    func decryptPayload<T: Decodable>(encryptedData: Data, nonce: Data, sharedKey: Data? = nil)
        throws -> T
    {
        if sharedKey == nil { checkIsConnected() }

        if encryptedData == nil || nonce == nil {
            throw SolanaWalletAdapterError.invalidResponse
        }

        // Decrypt the message
        let data = try SaltSecretBox.open(
            box: encryptedData,
            nonce: nonce,
            key: sharedKey ?? connection!.encryption.sharedKey)

        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Encrypt the payload dictionary
    func encryptPayload(payload: [String: Any], nonce: Data) throws -> Data {
        checkIsConnected()

        let payloadJson = try JSONSerialization.data(withJSONObject: payload)
        let encryptedPayload = try SaltSecretBox.secretBox(
            message: payloadJson,
            nonce: nonce,
            key: connection!.encryption.sharedKey
        )
        return encryptedPayload
    }
}
