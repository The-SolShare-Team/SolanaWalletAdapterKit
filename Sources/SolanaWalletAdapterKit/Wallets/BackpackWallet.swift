import Foundation
import UIKit
import CryptoKit
import SolanaKit
//note to self, make a constants page with urls, error messages, etc.
// add protocl wallet later
final class BackpackWallet:  ObservableObject{
    @Published var isConnected: Bool = false
    
    var dappUserPublicKey: String?
    var dappEncryptionPrivateKey: Curve25519.KeyAgreement.PrivateKey = Curve25519.KeyAgreement.PrivateKey()
    var dappEncryptionPublicKey: Data {dappEncryptionPrivateKey.publicKey.rawRepresentation}
    var dappEncryptionSharedKey: SymmetricKey?
    var session: String?
    
    
    
    
    //Connect
    
    //handle the redirect logic after connect() has been called
    func handleConnectRedirect(_ url: URL) async throws {
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        // no error thrown, success handling
        try onConnectionSuccess(payload: params)
    }
    
    //success handler, might've added too much error handling, TBD
    func onConnectionSuccess(payload: [String: String]) throws{
        //keys for relevant return params
        let encryptionPublicKeyName = "wallet_xxx"
        let dataKey = "data"
        let nonceKey = "nonce"
        
        dappEncryptionSharedKey = try Utils.computeSharedKey(walletEncPubKeyB58: payload[encryptionPublicKeyName]!, encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, dappEncryptionPrivateKey: dappEncryptionPrivateKey)
        
        let data = try Utils.decryptBackpackData(encryptedDataB58: payload[dataKey]!, nonceB58: payload[nonceKey]!, symmetricKey: dappEncryptionSharedKey!)
        
        dappUserPublicKey = data["public_key"]
        session = data["session"] // stays base58 encoded
        isConnected = true
        
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
    
    
    //Disconnect
    
    func generateDisconnectUrl(_ nonce: String, _ redirectLink: String, _ payload: String) async throws -> URL?{
        let disconnectURL = "https://backpack.app/ul/v1/disconnect"
        var params: [String: String?] = [
            "dapp_encryption_public_key": Utils.base58Encode(dappEncryptionPublicKey),
            "nonce": nonce,
            "redirect_link": redirectLink,
            "payload": payload
        ]
        //note: trying to keep Utils.base58Encode as we pass into params for consistency
        guard let url = Utils.buildURL(baseURL: disconnectURL, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    
    func handleDisconnectRedirect(_ url: URL) async throws {
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        // clear everything
        session = nil
        dappEncryptionSharedKey = nil
        isConnected = false
        dappUserPublicKey = nil
        dappEncryptionPrivateKey = Curve25519.KeyAgreement.PrivateKey() // generate new key pair
    }
    
    //Note: Payload can and probably should be handled internally as much as possible
    func disconnect(nonce: String?, redirectLink: String ) async throws{
        // Implementation
        let finalNonce = nonce ?? Utils.base58Encode(Utils.generateNonce())
        let payloadDict: [String: String] = ["session": session!]
        let payloadJson = try JSONSerialization.data(withJSONObject: payloadDict)
        let payload = Utils.base58Encode(payloadJson)
        let url = try await generateDisconnectUrl(finalNonce, redirectLink, payload)
        await MainActor.run {
            UIApplication.shared.open(url!)
        }
    }
    
    //Sign and Send Transaction
    
    func generateSignAndSendTransactionUrl(_ nonce: String, _ redirectLink: String, _ payload: String) async throws -> URL? {
        let signAndSendTransactionUrl = "https://backpack.app/ul/v1/signAndSendTransaction"
        
        var params: [String: String?] = [
            "dapp_encryption_public_key": Utils.base58Encode(dappEncryptionPublicKey),
            "nonce": nonce,
            "redirect_link": redirectLink,
            "payload": payload
        ]
        
        
        
        guard let url = Utils.buildURL(baseURL: signAndSendTransactionUrl, queryParams: params) else {
            throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url
    }
    
    func handleSignAndSendTransactionRedirect(_ url: URL) async throws {
        let params = Utils.parseUrl(url)
        try Utils.onFailure(params)
        // implmentation for success
        
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
