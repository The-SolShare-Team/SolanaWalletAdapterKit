import Foundation
import UIKit
import SolanaKit
import TweetNacl
//note to self, make a constants page with urls, error messages, etc.
// add protocl wallet later
final class BackpackWallet:  ObservableObject{
    @Published var isConnected: Bool = false
    
    var dappUserPublicKey: String?
    
    var dappEncryptionPrivateKey: Box.KeyPair.PrivateKey = Box.KeyPair.generate().privateKey
    var dappEncryptionPublicKey: Data {
        Box.KeyPair.publicKey(from: dappEncryptionPrivateKey)
    }
    var dappEncryptionSharedKey: Data?
    var session: String?
    
//    var dappEncryptionPrivateKey: Curve25519.KeyAgreement.PrivateKey = Curve25519.KeyAgreement.PrivateKey()
//    var dappEncryptionPublicKey: Data {dappEncryptionPrivateKey.publicKey.rawRepresentation}
//    var dappEncryptionSharedKey: SymmetricKey?
    
    //Connect
    
    //handle the redirect logic after connect() has been called
    func handleConnectRedirect(_ url: URL) async throws -> ConnectResponse {
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        // no error thrown, success handling
        return try onConnectionSuccess(payload: params)
    }
    
    //success handler, might've added too much error handling, TBD
    func onConnectionSuccess(payload: [String: String]) throws -> ConnectResponse{
        //keys for relevant return params
        let encryptionPublicKeyName = "wallet_xxx"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        dappEncryptionSharedKey = try Utils.computeSharedKey(walletEncPubKeyB58: payload[encryptionPublicKeyName]!, encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, dappEncryptionPrivateKey: dappEncryptionPrivateKey)
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        
        dappUserPublicKey = data["public_key"]
        session = data["session"] // base58 encoded string
        isConnected = true
        
        return ConnectResponse(
                encryptionPublicKey: wallet[]
                userPublicKey: data["public_key"] ?? "",
                session: data["session"] ?? "",
                nonce: payload[nonceKey] ?? ""
            )
        
    }
        
    func generateConnectUrl(_ appUrl: String, _ redirectLink: String, _ cluster: String?) async throws -> URL?{
        let connectURL = "https://backpack.app/ul/v1/connect"
        let params: [String: String?] = [
                    "app_url": appUrl,
                    "dapp_encryption_public_key": Utils.base58Encode(dappEncryptionPublicKey),
                    "redirect_link": redirectLink,
                    "cluster": cluster ?? nil
        ] //query string params for connect()  https://docs.backpack.app/deeplinks/provider-methods/connect
        guard let url = Utils.buildURL(baseURL: connectURL, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    
    
    func connect(appUrl: String, redirectLink: String, cluster: String?) async throws {
        // Implementation
        let url = try await generateConnectUrl(appUrl, redirectLink, cluster)
        await MainActor.run {
            UIApplication.shared.open(url!)
        }
        
    }
    
    //general deep link urls (connect is the only one that is different)
    // no  need to pass public key
    func generateUnivLinkUrl(
        _ baseURL: String,
        _ nonce: String,
        _ redirectLink: String,
        _ payload: String
    ) async throws -> URL? {
        // The DApp's public key needs to be Base58 encoded for the URL
        
        var params: [String: String?] = [
            "dapp_encryption_public_key": Utils.base58Encode(dappEncryptionPublicKey)
            "nonce": nonce,
            "redirect_link": redirectLink,
            "payload": payload
        ]
        
        // Note: redirectLink MUST be URL-encoded, which Utils.buildURL should handle.
        
        guard let url = Utils.buildURL(baseURL: baseURL, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    // no need to pass shared key, nonce
    func executeDeepLinkAction(
        _ baseURL: String,
        _ redirectLink: String,
        _ payloadDict: [String: String]
    ) async throws {
        
        // 1. Generate Nonce
        let nonce = Utils.base58Encode(Utils.generateNonce())
        // 2. Encrypt payload
        let payload = Utils.encryptPayload(
                dappEncryptionSharedKey: dappEncryptionSharedKey,
                payload: payloadDict,
                nonce: nonce
        )
        
        let url = try await generateUnivLinkUrl(baseURL, nonce, redirectLink, payload)
        await MainActor.run {
                UIApplication.shared.open(url)
    }
    
    //Disconnect
    
    func handleDisconnectRedirect(_ url: URL) async throws {
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        // clear everything
        session = nil
        dappEncryptionSharedKey = nil
        isConnected = false
        dappUserPublicKey = nil
        dappEncryptionPrivateKey = Box.KeyPair.generate().privateKey
        /*dappEncryptionPrivateKey = Curve25519.KeyAgreement.PrivateKey()*/ // generate new key pair
    }
    
    //Note: Payload can and probably should be handled internally as much as possible
    func disconnect( redirectLink: String ) async throws{
        // Implementation
        payloadDict = ["session": session!]
        let baseURL = "https://backpack.app/ul/v1/disconnect"
        try await executeDeepLinkAction(baseURL, redirectLink, payLoadDict)
    }
    
    //Sign and Send Transaction
    
    
    func handleSignAndSendTransactionRedirect(_ url: URL) async throws ->  SignAndSendTransactionResponse{
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        return try onSignAndSendTransactionSuccess(payload: params)
        
    }
    
    func onSignAndSendTransactionSuccess(payload: [String: String]) throws  -> SignAndSendTransactionResponse{
        let signatureKey = "signature"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        return SignAndSendTransactionResponse (
            signature: data[signatureKey],
            nonce: payload[nonceKey]
        )
    }
    
    func signAndSendTransaction( redirectLink: String, transaction : Data, sendOptions: TransactionOptions?) async throws {
        // Implementation
        let encodedTransaction: String = Utils.base58Encode( transaction)
        payloadDict = [
            "transaction": encodedTransaction,
            "sessions": session!,
        ]
        if let options = SendOptions {
            let optionsData = try JSONEncoder().encode(options)
            guard let optionsString = String(data: optionsData, encoding: .utf8) else {
                throw NSError(domain: "BackpackWallet", code: 3, userInfo: [NSLocalizedDescriptionKey: "Json serialization failed"])
            }
            payloadDict["sendOptions"] = optionsString
        }
        
        let baseURL = "https://backpack.app/ul/v1/signAndSendTransaction"
        try await executeDeepLinkAction(baseURL, redirectLink, payLoadDict)
        
    }
    
    //Sign all transactions
    
    func handleSignAllTransactionsRedirect(_ url: URL) async throws ->  SignAllTransactionsResponse{
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        return try onSignAllTransactionsSuccess(payload: params)
        
    }
        
    func onSignAllTransactionsSuccess(payload: [String: String]) throws -> SignAllTransactionsResponse{
        let transactionsKey = "transactions"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        return SignAllTransactionsResponse(
            transactions: data[transactionsKey],
            nonce: payload[nonceKey]
        )
    }
    
    
    
    func signAllTransactions(redirectLink: String, transactions: [Data]) async throws {
        // Implementation
        let encodedTransactions: [String] = transactions.map { rawData in
                return Utils.base58Encode(rawData)
        }
        let transactionsData = try JSONSerialization.data(withJSONObject: encodedTransactions, options: [])
        guard let transactionsString = String(data: transactionsData, encoding: .utf8) else {
            throw NSError(domain: "BackpackWallet", code: 3, userInfo: [NSLocalizedDescriptionKey: "Json serialization failed"])
        }
        
        payloadDict = [
            "transactions": transactionsString,
            "sessions": session!,
        ]
        let baseURL = "https://backpack.app/ul/v1/signAndSendTransaction"
        try await executeDeepLinkAction(baseURL, redirectLink, payLoadDict)
    }
      
    // sign transaction
        
    func handleSignTransactionRedirect(_ url: URL) async throws ->  SignTransactionResponse{
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        return try onSignTransactionSuccess(payload: params)
        
    }
        
    func onSignTransactionSuccess(payload: [String: String]) throws -> SignTransactionResponse{
        let transactionKey = "transaction"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        return SignTransactionResponse(
            nonce: payload[nonceKey]!,
            transaction: data[transactionKey]
        )
    }
        
    func signTransaction(redirectLink: String, transaction: Data) async throws {
    // Implementation
        let encodedTransaction: String = Utils.base58Encode(transaction)
        
        let payloadDict = [
            "transaction": encodedTransaction,
            "session": session!,
        ]
        let baseURL = "https://backpack.app/ul/v1/signTransaction"
        try await executeDeepLinkAction(baseURL, redirectLink, payLoadDict)
        
    }

    // sign message
        
    func handleSignMessageRedirect(_ url: URL) async throws ->  SignMessageResponse{
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        return try onSignMessageSuccess(payload: params)
        
    }
        
    func onSignMessageSuccess(payload: [String: String]) throws -> SignMessageResponse{
        let signatureKey = "signature"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        let data = try Utils.decryptPayload(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, sharedKey: dappEncryptionSharedKey!)
        return SignTransactionResponse(
            nonce: payload[nonceKey]!,
            signature: data[signatureKey]
        )
    }
    
    func signMessage(redirectLink: String, message: String, encodingFormat: EncodingFormat?) async throws {
        //default behaviour is utf-8
        let encoding = encodingFormat ?? EncodingFormat(rawValue: "utf-8")
        let messageData = try Utils.messageStringToData(encodedMessage: message, encoding: encoding)
        let payloadDict = [
            "message:" Utils.base58Encode(messageData)
            "session": session!,
            
        ]
        if let encoding = encodingFormat {
            payloadDict["display"] = encoding.rawValue
        }
        let baseURL = "https://backpack.app/ul/v1/signMessage"
        try await executeDeepLinkAction(baseURL, redirectLink, payloadDict)
        
        
    }
    
    func browse(url: String, ref: String) async throws {
        // Implementation
    }
}
