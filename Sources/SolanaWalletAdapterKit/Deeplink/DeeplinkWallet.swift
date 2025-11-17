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

public struct DeeplinkWalletConnection: WalletConnection {
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

    public let session: String
    public let encryption: DiffieHellmanData
    public let walletPublicKey: PublicKey

    public init(
        session: String,
        encryption: DiffieHellmanData,
        walletPublicKey: PublicKey
    ) {
        self.session = session
        self.encryption = encryption
        self.walletPublicKey = walletPublicKey
    }
}

public protocol DeeplinkWallet: Wallet {
    static var baseURL: URL { get }
    static var walletEncryptionPublicKeyIdentifier: String { get }
    var connection: DeeplinkWalletConnection? { get set }
}

extension DeeplinkWallet {
    var activeConnection: DeeplinkWalletConnection {
        get throws {
            guard let connection else {
                throw SolanaWalletAdapterError.notConnected
            }
            return connection
        }
    }

    /**
        Pair with the wallet.
    */
    public mutating func connect() async throws -> DeeplinkWalletConnection? {
        guard connection == nil else { throw SolanaWalletAdapterError.alreadyConnected }

        let encryptionKeyPair = try SaltBox.keyPair()
        let deeplink = {
            let endpointURL = Self.baseURL.appendingPathComponent("connect")
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
        guard let walletEncryptionPublicKey = response[Self.walletEncryptionPublicKeyIdentifier],
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
            walletPublicKey: PublicKey(decryptedData.publicKey))

        self.connection = newConnection
        return newConnection
    }

    /**
        Unpair from the wallet.
    */
    public mutating func disconnect() async throws -> DeeplinkWalletConnection? {
        let connection = try activeConnection

        let endpointURL: URL = Self.baseURL.appendingPathComponent("disconnect")

        // Request
        let payload = DisconnectRequestPayload(session: connection.session)
        let deeplink = try generateNonConnectDeeplinkURL(
            endpointUrl: endpointURL, payload: payload)

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        try throwIfErrorResponse(response: response)
    }

    /**
        Sign and send a transaction.
    */
    public func signAndSendTransaction(transaction: Transaction, sendOptions: SendOptions? = nil)
        async throws -> SignAndSendTransactionResponseData
    {
        let connection = try activeConnection

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

    /**
        Sign all transactions.
    */
    public func signAllTransactions(transactions: [Transaction])
        async throws -> SignAllTransactionsResponseData
    {
        let connection = try activeConnection

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

    /**
        Sign a transaction.
    */
    public func signTransaction(transaction: Transaction)
        async throws -> SignTransactionResponseData
    {
        let connection = try activeConnection

        let encodedTransaction = try transaction.encode().base58EncodedString()
        let payload = SignTransactionRequestPayload(
            transaction: encodedTransaction,
            session: connection.session)

        return try await performSigningCall(
            endpoint: "signTransaction",
            payload: payload
        )
    }

    /**
        Sign a message.
    */
    public func signMessage(message: Data, display: MessageDisplayFormat? = nil)
        async throws -> SignMessageResponseData
    {
        let connection = try activeConnection

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

    /**
        Browse to a URL.
    */
    public func browse(url: URL, ref: URL) async throws {
        guard
            let encodedTargetURL = url.absoluteString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let encodedRefURL = ref.absoluteString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed)
        else {
            throw SolanaWalletAdapterError.invalidRequest
        }

        let deeplink = try {
            let endpointURL = Self.baseURL.appendingPathComponent("browse")
            guard
                var components = URLComponents(
                    url: endpointURL.appendingPathComponent(encodedTargetURL),
                    resolvingAgainstBaseURL: false)
            else {
                throw SolanaWalletAdapterError.invalidRequest
            }
            components.queryItems = [
                URLQueryItem(name: "ref", value: encodedRefURL)
            ]
            return components.url!  // TODO: Is it safe to force unwrap here?
        }()

        #if os(iOS)
            let success = await UIApplication.shared.open(deeplink)
            if !success { throw DeeplinkFetchingError.unableToOpen }  // TODO: Not sure about this error
        #elseif os(macOS)
            let success = NSWorkspace.shared.open(deeplink)
            if !success { throw DeeplinkFetchingError.unableToOpen }  // TODO: Not sure about this error
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
        let endpointURL = Self.baseURL.appendingPathComponent(endpoint)
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
            throw SolanaWalletAdapterError.invalidResponse
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
        let connection = try activeConnection

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
                throw SolanaWalletAdapterError.invalidResponse
            }
            throw SolanaWalletAdapterError(walletErrorCode: errorCode, message: errorMessage)
        }
    }

    /// Decrypt the encrypted payload into the specified type
    /// If a sharedKey is not provided, the connection.encryption.sharedKey is used
    func decryptPayload<T: Decodable>(encryptedData: Data, nonce: Data, sharedKey: Data? = nil)
        throws -> T
    {
        var connection: DeeplinkWalletConnection
        if sharedKey == nil { connection = try activeConnection }

        // Decrypt the message
        let data = try SaltSecretBox.open(
            box: encryptedData,
            nonce: nonce,
            key: sharedKey ?? connection.encryption.sharedKey)

        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Encrypt the payload dictionary
    func encryptPayload<T: Encodable>(payload: T, nonce: Data) throws -> Data {
        let connection = try activeConnection

        let payloadJson = try JSONEncoder().encode(payload)
        let encryptedPayload = try SaltSecretBox.secretBox(
            message: payloadJson,
            nonce: nonce,
            key: connection.encryption.sharedKey
        )

        return encryptedPayload
    }
}
