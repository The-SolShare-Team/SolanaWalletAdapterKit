import Foundation
import SolanaKit
import CryptoKit
import TweetNacl
//note to self, make a constants page with urls, error messages, etc.
// add protocol wallet later
final class BackpackWallet: Wallet, ObservableObject{
    @Published var isConnected: Bool
    var provider : WalletProvider = WalletProvider.backpack
    
    var dappUserPublicKey: String?
    
    private var dappEncryptionPrivateKey: Curve25519.KeyAgreement.PrivateKey
    var dappEncryptionPublicKey: Curve25519.KeyAgreement.PublicKey
//    var dappEncryptionSolanaKey: SolanaPublicKey
    var dappEncryptionSharedKey: SymmetricKey?
    var session: String?
    
    func getDappEncryptionPrivateKey () -> Curve25519.KeyAgreement.PrivateKey {
        return dappEncryptionPrivateKey
    }
    func setDappEncryptionPrivateKey (_ newKey: Curve25519.KeyAgreement.PrivateKey) {
        dappEncryptionPrivateKey = newKey
    }
    
    init(privateKey: Curve25519.KeyAgreement.PrivateKey? = nil) {
        if let privKey = privateKey {
            dappEncryptionPrivateKey = privKey
        }else {
            dappEncryptionPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        }
        dappEncryptionPublicKey = dappEncryptionPrivateKey.publicKey
//        dappEncryptionSolanaKey = SolanaPublicKey(bytes: ByteArrayKt.toByteArray(dappEncryptionPublicKey.rawRepresentation))
        self.isConnected = false
    }
    
    
//    var dappEncryptionPrivateKey: Curve25519.KeyAgreement.PrivateKey = Curve25519.KeyAgreement.PrivateKey()
//    var dappEncryptionPublicKey: Data {dappEncryptionPrivateKey.publicKey.rawRepresentation}
//    var dappEncryptionSharedKey: SymmetricKey?
    
    //Connect
    
    // overloaded handleredirect function
    
    func handleRedirect<T: WalletResponse>(
        _ url: URL,
        successHandler: ([String: String]) throws -> T
    ) async throws -> T {
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        return try successHandler(params)
    }
    
    func handleRedirect(
        _ url: URL,
        successHandler: ([String: String]) throws -> Void
    ) async throws {
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        try successHandler(params)
    }
    
    //handle the redirect logic after connect() has been called
    func handleConnectRedirect(_ url: URL) async throws -> ConnectResponse {
        try await handleRedirect(url, successHandler: onConnectionSuccess)
    }
    
    //success handler, might've added too much error handling, TBD
    func onConnectionSuccess(payload: [String: String]) throws -> ConnectResponse{
        //keys for relevant return params
        let encryptionPublicKeyName = "wallet_xxx"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        dappEncryptionSharedKey = try Utils.computeSharedKey(walletEncPubKeyB58: payload[encryptionPublicKeyName]!, dappEncryptionPrivateKey: dappEncryptionPrivateKey)
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        
        
        
        dappUserPublicKey = (data["public_key"] as! String)
        session = (data["session"] as! String )// base58 encoded string
        isConnected = true
        
        return ConnectResponse(
            encryptionPublicKey: dappEncryptionPublicKey.rawRepresentation,
                userPublicKey: dappUserPublicKey!,
                session: session!,
                nonce: payload[nonceKey] ?? ""
            )
        
    }
        
    func generateConnectUrl(_ appUrl: String, _ redirectLink: String, _ cluster: String?) async throws -> URL?{
        let connectURL = "https://backpack.app/ul/v1/connect"
        var params: [String: String?] = [
                    "app_url": appUrl,
                    "dapp_encryption_public_key": Utils.base58Encode(dappEncryptionPublicKey.rawRepresentation),
                    "redirect_link": redirectLink,
        ] //query string params for connect()  https://docs.backpack.app/deeplinks/provider-methods/connect
        if let clust = cluster {
            params["cluster"] = clust
        }
        guard let url = Utils.buildURL(baseURL: connectURL, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    
    
    func connect(appUrl: String, redirectLink: String, cluster: String?) async throws -> URL{
        // Implementation
        let url = try await generateConnectUrl(appUrl, redirectLink, cluster)
        return url!
        
    }
    
    //general deep link urls (connect is the only one that is different)
    // no  need to pass public key
    // no need to pass shared key, nonce
    func generateUnivLink(
        _ baseURL: String,
        _ redirectLink: String,
        _ payloadDict: [String: String]
    ) async throws -> URL {
        
        // 1. Generate Nonce
        let nonce = Utils.base58Encode(Utils.generateNonce())
        // 2. Encrypt payload
        let payload = try Utils.encryptPayload(
                sharedKey: dappEncryptionSharedKey!,
                payload: payloadDict,
                nonce: nonce
        )
        let params: [String: String?] = [
            "dapp_encryption_public_key": Utils.base58Encode(dappEncryptionPublicKey.rawRepresentation),
            "nonce": nonce,
            "redirect_link": redirectLink,
            "payload": payload
        ]
        guard let url = Utils.buildURL(baseURL: baseURL, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    
    //Disconnect
    
    func handleDisconnectRedirect(_ url: URL) async throws {
        try await handleRedirect(url, successHandler: onDisconnectSuccess)
    }
    
    func onDisconnectSuccess(_ params: [String: String]) throws {
        // clear everything
        session = nil
        dappEncryptionSharedKey = nil
        isConnected = false
        dappUserPublicKey = nil
//        (dappEncryptionPublicKey, dappEncryptionPrivateKey) = try NaclBox.keyPair()
        dappEncryptionPrivateKey = Curve25519.KeyAgreement.PrivateKey() // generate new key pair
        dappEncryptionPublicKey = dappEncryptionPrivateKey.publicKey
    }
    
    //Note: Payload can and probably should be handled internally as much as possible
    func disconnect( redirectLink: String ) async throws -> URL{
        // Implementation
        let payloadDict = ["session": session!]
        let baseURL = "https://backpack.app/ul/v1/disconnect"
        return try await generateUnivLink(baseURL, redirectLink, payloadDict)
    }
    
    //Sign and Send Transaction
    
    
    func handleSignAndSendTransactionRedirect(_ url: URL) async throws -> SignTransactionResponse {
        try await handleRedirect(url, successHandler: onSignTransactionSuccess)
    }
    
    func onSignAndSendTransactionSuccess(payload: [String: String]) throws  -> SignAndSendTransactionResponse{
        let signatureKey = "signature"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        return SignAndSendTransactionResponse (
            nonce: payload[nonceKey]!,
            signature: data[signatureKey]! as! String,
            )
    }
    
    //note: might have to change conversion from TransactionOption from web3 to String
        //currently assuming the conversion is trivial, it may not be
        //nvm it is NOT trivial 
    func signAndSendTransaction( redirectLink: String, transaction: Data, sendOptions: SendOptions?) async throws -> URL {
        // Implementation
        let encodedTransaction: String = Utils.base58Encode( transaction)
        var payloadDict = [
            "transaction": encodedTransaction,
            "sessions": session!,
        ]
        if let options = sendOptions {
            let optionsData = try JSONEncoder().encode(options)
            guard let optionsString = String(data: optionsData, encoding: .utf8) else {
                throw NSError(domain: "BackpackWallet", code: 3, userInfo: [NSLocalizedDescriptionKey: "Json serialization failed"])
            }
            payloadDict["sendOptions"] = optionsString
        }
        
        let baseURL = "https://backpack.app/ul/v1/signAndSendTransaction"
        return try await generateUnivLink(baseURL, redirectLink, payloadDict)
        
    }
    
    //Sign all transactions
    
    func handleSignAllTransactionsRedirect(_ url: URL) async throws -> SignAllTransactionsResponse {
        try await handleRedirect(url, successHandler: onSignAllTransactionsSuccess)
    }

        
    func onSignAllTransactionsSuccess(payload: [String: String]) throws -> SignAllTransactionsResponse{
        let transactionsKey = "transactions"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        return SignAllTransactionsResponse(
            nonce: payload[nonceKey]!,
            transactions: data[transactionsKey]! as! [String],
            
        )
    }
    
    
    
    func signAllTransactions(redirectLink: String, transactions: [Data]) async throws -> URL{
        // Implementation
        let encodedTransactions: [String] = transactions.map { rawData in
                return Utils.base58Encode(rawData)
        }
        let transactionsData = try JSONSerialization.data(withJSONObject: encodedTransactions, options: [])
        guard let transactionsString = String(data: transactionsData, encoding: .utf8) else {
            throw NSError(domain: "BackpackWallet", code: 3, userInfo: [NSLocalizedDescriptionKey: "Json serialization failed"])
        }
        
        let payloadDict = [
            "transactions": transactionsString,
            "sessions": session!,
        ]
        let baseURL = "https://backpack.app/ul/v1/signAndSendTransaction"
        return try await generateUnivLink(baseURL, redirectLink, payloadDict)
    }
      
    // sign transaction
        
    func handleSignTransactionRedirect(_ url: URL) async throws -> SignTransactionResponse {
        try await handleRedirect(url, successHandler: onSignTransactionSuccess)
    }
        
    func onSignTransactionSuccess(payload: [String: String]) throws -> SignTransactionResponse{
        let transactionKey = "transaction"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        return SignTransactionResponse(
            nonce: payload[nonceKey]!,
            transaction: data[transactionKey]! as! String
        )
    }
        
    func signTransaction(redirectLink: String, transaction: Data) async throws -> URL {
    // Implementation
        let encodedTransaction: String = Utils.base58Encode(transaction)
        
        let payloadDict = [
            "transaction": encodedTransaction,
            "session": session!,
        ]
        let baseURL = "https://backpack.app/ul/v1/signTransaction"
        return try await generateUnivLink(baseURL, redirectLink, payloadDict)
        
    }

    // sign message
        
    func handleSignMessageRedirect(_ url: URL) async throws -> SignMessageResponse {
        try await handleRedirect(url, successHandler: onSignMessageSuccess)
    }
        
    func onSignMessageSuccess(payload: [String: String]) throws -> SignMessageResponse{
        let signatureKey = "signature"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        return SignMessageResponse(
            nonce: payload[nonceKey]!,
            signature: data[signatureKey]! as! String,
        )
    }
    
    func signMessage(redirectLink: String, message: String, encodingFormat: EncodingFormat?) async throws -> URL {
        //default behaviour is utf-8
        let encoding: EncodingFormat = encodingFormat ?? .utf8
        let messageData = try Utils.messageStringToData(encodedMessage: message, encoding: encoding)
        var payloadDict = [
            "message": Utils.base58Encode(messageData),
            "session": session!,
            
        ]
        if let encoding = encodingFormat {
            payloadDict["display"] = encoding.rawValue
        }
        let baseURL = "https://backpack.app/ul/v1/signMessage"
        return try await generateUnivLink(baseURL, redirectLink, payloadDict)
        
        
    }
    
    func browse(url: String, ref: String) async throws -> URL{
        let baseURL = "https://backpack.app/ul/v1/browse/\(url)"
        let params = ["ref": ref]
        let url = Utils.buildURL(baseURL: baseURL, queryParams: params)
        return url!
    }
}
