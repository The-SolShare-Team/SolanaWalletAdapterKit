import Foundation
import UIKit
import TweetNacl
import CryptoKit

//note to self, make a constants page with urls, error messages, etc.

final class BackpackWallet: Wallet, ObservableObject{
    var dappUserPublicKey: String?
    @Published var isConnected: Bool = false
    var dappEncryptionKeyPair: (publicKey: Data, secretKey: Data) = NaclBox.keyPair()
    var dappEncryptionSharedKey: Data?
    var session: String?
    
    
    //Utils
    
    //gen purpose url builder, takes in base url string and a dictionary of query string params
    func buildURL(baseURL: String, queryParams: [String: String?]) -> URL? {
        var components = URLComponents(string: baseURL)!
        
        var queryItems: [URLQueryItem] = []
        
        for (key, value) in queryParams {
            if let value = value {
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                queryItems.append(URLQueryItem(name: key, value: encodedValue))
            }
        }
        components.queryItems = queryItems
        return components.url!
    }
    
    //gen url parser
    func parseUrl(_ url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in item.value.map
            { (item.name, $0)} })
        return params
    }
    // gen failure handler, everything returns an error code and an error message
    func onFailure(_ payload: [String: String]) async throws {
        if let errorCode = payload["errorCode"], let errorMessage = payload["errorMessage"] {
            throw NSError(domain: "BackpackWallet", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failure to connect -- Error \(errorCode): \(errorMessage)"])
        }
    }
    
    // generate nonce
    func generateNonce() -> Data {
        var nonce = Data(count: 24)
        _ = nonce.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 24, $0.baseAddress!) }
        return nonce
    }
    
    //Connect
    
    //handle the redirect logic after connect() has been called
    func handleConnectRedirect(_ url: URL) async throws {
        let params = parseUrl(url)
        try onFailure(params)
        // no error thrown, success handling
        try onConnectionSuccess(payload: params)
    }
    
    //success handler, might've added too much error handling, TBD
    func onConnectionSuccess(payload: [String: String?]) async throws{
        //keys for relevant return params
        let encryptionPublicKeyName = "wallet_xxx"
        let dataKey = "data"
        let nonceKey = "nonce"
        //error handling for getting required payload fields, making sure all exist: (might remove in future)
        guard let walletEncryptionPubKeyB58 = payload[encryptionPublicKeyName],
          let dataB58 = payload[dataKey],
          let nonceB58 = payload[nonceKey] else {
            throw NSError(domain: "BackpackWallet", code: 2, userInfo: [NSLocalizedDescriptionKey: "Missing required payload fields"])
        }
        
        //error handling for base58 decode
        guard let walletEncryptionPubKeyData = Data(Base58.decode(walletEncPubB58)),
          let cipherText = Data(Base58.decode(dataB58)),
          let nonce = Data(Base58.decode(nonceB58)) else {
            throw NSError(domain: "BackpackWallet", code: 3, userInfo: [NSLocalizedDescriptionKey: "Base58 decoding failed"])
        }
        
        //store shared key, computed from wallet public key and our private key
        dappEncryptionSharedKey = try NaclBox.before(
            publicKey: walletEncryptionPubKeyData,
            secretKey: dappEncryptionKeyPair.secretKey
        )
        //decipher the data for use
        let message = try NaclSecretBox.open(
            box: cipherText,
            nonce: nonce,
            key: dappEncryptionSharedKey!
        )
        guard let data = try JSONSerialization.jsonObject(with: message, options: []) as? [String: String] else {
            throw NSError(domain: "BackpackWallet", code: 4, userInfo: [NSLocalizedDescriptionKey: "Decrypted message is not valid JSON"])
        }
        // store our user public key, session string
        print(data)
        dappUserPublicKey = data["public_key"]
        session = data["session"] // stays base58 encoded
        isConnected = true
    }
        
    func generateConnectUrl(_ appUrl: String, _ redirectLink: String, _ cluster: String?) async throws -> URL?{
        let connectURL = "https://backpack.app/ul/v1/connect"
        let params: [String: String?] = [
                    "app_url": appUrl,
                    "dapp_encryption_public_key": Base58.encode(dappEncryptionKeyPair.publicKey),
                    "redirect_link": redirectLink,
                    "cluster": cluster ?? nil
        ] //query string params for connect()  https://docs.backpack.app/deeplinks/provider-methods/connect
        guard let url = buildURL(baseURL: connectURL, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    
    
    func connect(appUrl: String, redirectLink: String, cluster: String?) async throws {
        // Implementation
        let url = try generateConnectUrl(appUrl, redirectLink, cluster)
        await MainActor.run {
            UIApplication.shared.open(url)
        }
        
    }
    
    
    //Disconnect
    
    func generateDisconnectUrl(_ nonce: String, _ redirectLink: String) async throws{
        let disconnectURL = "https://backpack.app/ul/v1/disconnect"
        let payloadDict: [String: String] = ["session": session!]
        let payloadJson = try JSONSerialization.data(withJSONObject: payloadDict)
        var params: [String: String?] = [
            "dapp_encryption_public_key": Base58.encode(dappEncryptionKeyPair.publicKey),
            "nonce": Base58.encode(nonce),
            "redirect_link": redirectLink,
            "payload": Base58.encode (payloadJson)
        ]
        //note: trying to keep base58.encode as we pass into params for consistency
        guard let url = buildURL(baseURL: disconnectURL, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    
    func handleDisconnectRedirect(_ url: URL) async throws {
        let params = parseUrl(url)
        try onFailure(params)
        // returns nothing for successful disconnect
    }
    
    //Note: Payload can and probably should be handled internally as much as possible
    func disconnect(nonce: String?, redirectLink: String ) async throws{
        // Implementation
        let finalNonce = nonce ?? generateNonce()
        let url = try generateDisconnectUrl(finalNonce, redirectLink)
        await MainActor.run {
            UIApplication.shared.open(url)
        }
    }
    
    //Sign and Send Transaction
    
    func generateSignAndSendTransactionUrl(_ nonce: String, _ redirectLink: String, ) async throws -> URL? {
        let signAndSendTransactionUrl = "https://backpack.app/ul/v1/signAndSendTransaction"
        var params: [String: String?] = [
            "dapp_encryption_public_key": Base58.encode(dappEncryptionKeyPair.publicKey),
            "nonce": Base58.encode(nonce),
            "redirect_link": redirectLink,
            "payload": Base58.encode (payloadJson)
        ]
        
        guard let url = buildURL(baseURL: disconnectURL, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    
    func handleSignAndSendTransactionRedirect(_ url: URL) async throws {
        let params = parseUrl(url)
        try onFailure(params)
        // implmenetation for success
        
    }
    
    func signAndSendTransaction(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
        
    }
    func signAllTransactions(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    func signTransaction(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    func signMessage(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    
    func browse(url: String, ref: String) async throws {
        // Implementation
    }
}
