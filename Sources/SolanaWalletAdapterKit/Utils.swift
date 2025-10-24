//
//  Utils.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-17.
//

import Foundation
import CryptoKit
import TweetNacl

class Utils {
    private init() {}
    //Utils
    
    //gen purpose url builder, takes in base url string and a dictionary of query string params
    static func buildURL(baseURL: String, queryParams: [String: String?]) -> URL? {
        var components = URLComponents(string: baseURL)!
        
        var queryItems: [URLQueryItem] = []
        
        for (key, value) in queryParams {
            if let value = value {
                queryItems.append(URLQueryItem(name: key, value: value))
            }
        }
        components.queryItems = queryItems
        return components.url!
    }
    
    //gen url parser
    static func parseUrl(_ url: URL) -> [String: String] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in item.value.map
            { (item.name, $0)} })
        return params
    }
    
    // gen failure handler, everything returns an error code and an error message
    static func onFailure(_ payload: [String: String]) throws {
        if let errorCode = payload["errorCode"], let errorMessage = payload["errorMessage"] {
            throw NSError(domain: "BackpackWallet", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failure to connect -- Error \(errorCode): \(errorMessage)"])
        }
    }
    
    // generate nonce
    static func generateNonce(_ bytes:Int = 24) -> Data {
        var nonce = Data(count: bytes)
        _ = nonce.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 24, $0.baseAddress!) }
        return nonce
    }
    
    // base58 encode and alphabet
    //Ai generated
    static private let BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    static private let BASE58_ALPHABET_CHARS = Array(BASE58_ALPHABET)
    
    static func base58Encode(_ data: Data) -> String {
        if data.isEmpty { return "" }
        let byteArray = [UInt8](data)
        var zeroes = 0
        var length = 0
        var pbegin = 0
        let pend = byteArray.count
        while pbegin != pend && byteArray[pbegin] == 0 {
            pbegin += 1
            zeroes += 1
        }
        
        // Allocate enough space in big-endian base58 representation.
        let BASE = 58
        let iFACTOR = log(256.0) / log(Double(BASE))
        
        let size = Int(Double(pend - pbegin) * iFACTOR + 1.0)
        var b58 = [UInt8?](repeating: 0, count: size)
        while (pbegin != pend) {
            var carry = UInt32(byteArray[pbegin])
            var i = 0
            var it = size - 1
            while (carry != 0 || i < length) && it != -1 {
                carry += 256 * UInt32(b58[it]!)
                b58[it] = UInt8(carry % UInt32(BASE))
                carry = carry / UInt32(BASE)
                it -= 1
                i += 1
            }
//            if (carry != 0) { throw NSError(
//                domain: "Base58Encoding",
//                code: 1,
//                userInfo: [NSLocalizedDescriptionKey: "Non-zero carry"]
//            )}
            length = i
            pbegin+=1
        }
        var it2 = size - length
        while (it2 != size && b58[it2] == 0) {
          it2 += 1
        }
        var str = String(repeating: BASE58_ALPHABET_CHARS[0], count: zeroes)
        for it2 in it2..<size {
            str += String(BASE58_ALPHABET_CHARS[Int(b58[it2]!)])
        }
        return str
    }


    static func base58Decode(_ base58String: String) -> Data {
        if base58String.isEmpty { return Data() }

        var zeros = 0
        for ch in base58String {
            if ch == "1" { zeros += 1 } else { break }
        }

        var decoded: [UInt8] = []

        for ch in base58String {
            guard let digit = BASE58_ALPHABET_CHARS.firstIndex(of: ch) else {return Data()}
            var carry = digit
            var i = decoded.count - 1
            while i >= 0 {
                let val = Int(decoded[i]) * 58 + carry
                decoded[i] = UInt8(val & 0xff)
                carry = val >> 8
                i -= 1
            }
            while carry > 0 {
                decoded.insert(UInt8(carry & 0xff), at: 0)
                carry >>= 8
            }
        }

        if zeros > 0 {
            decoded.insert(contentsOf: Array(repeating: 0, count: zeros), at: 0)
        }

        return Data(decoded)
    }

    
    // need to cross reference with tweetnacl implementation to see byte sizes that work as well as wallet docs
    // https://github.com/bitmark-inc/tweetnacl-swiftwrap/tree/master/Sources/TweetNacl
    
    static func computeSharedKey(walletEncPubKeyB58: String, dappEncryptionPrivateKey: Curve25519.KeyAgreement.PrivateKey) throws -> SymmetricKey {
//        guard let walletPubKeyData = Utils.base58Decode(walletEncPubKeyB58) else {
//            throw NSError(domain: "Utils", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid wallet public key"])
//        }
//        let sharedKey = try NaclBox.before(publicKey: walletPubKeyData, secretKey: dappEncryptionPrivateKey)
//        return sharedKey
        
        let walletEncryptionPubKeyData = Utils.base58Decode(walletEncPubKeyB58)
        let backpackPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: walletEncryptionPubKeyData)
        let dappEncryptionSharedSecret = try dappEncryptionPrivateKey.sharedSecretFromKeyAgreement(with: backpackPublicKey)
        //decipher the data for use
        
        
        return dappEncryptionSharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32)
    }
    
    // base58 decoded and decrypted using shared secret generated symmetric key
    static func decryptPayload(encryptedDataB58: String, nonceB58: String, sharedKey:  SymmetricKey)
    throws -> [String: Any]{
        var data: [String: Any] = [:]
        let dataDecoded = Utils.base58Decode(encryptedDataB58)
        let nonceData = Utils.base58Decode(nonceB58)
        
        let message = try NaclSecretBox.open(box: dataDecoded, nonce: nonceData, key: sharedKey.withUnsafeBytes{Data($0)})
            
//        let nonce = try ChaChaPoly.Nonce(data: nonceData)
//        let sealedBox = try ChaChaPoly.SealedBox(
//            nonce: nonce,
//            ciphertext: dataDecoded.dropLast(16), // ciphertext
//            tag: dataDecoded.suffix(16) // authentication tag (16 bytes, length might be incorrect)
//        )
//        let message = try ChaChaPoly.open(sealedBox, using: symmetricKey)
        data = try JSONSerialization.jsonObject(with: message, options: []) as! [String: Any]
        
        return data
    }
    
    
    // encrypted, base58 encoded
    static func encryptPayload( sharedKey: SymmetricKey, payload: [String:String], nonce: String) throws -> String {
        let payloadJson = try JSONSerialization.data(withJSONObject: payload)
        let encryptedPayload = try NaclSecretBox.secretBox(
            message: payloadJson,
            nonce: Utils.base58Decode(nonce),
            key: sharedKey.withUnsafeBytes{Data($0)}
        )

        let payloadString = Utils.base58Encode(encryptedPayload)
        return payloadString
    }
    // note: swift Data and Uint8Aray are functionally the same thing: a contiguous block of raw, unsigned 8-bit integers (bytes)
    // so for now we convert the hex or utf-8 encoded message string supplied by the user and convert it to Data type, unlike what is exactly specified in https://docs.backpack.app/deeplinks/provider-methods/signmessage
    //if this sendMessage is not woorking as intended, this is a key point to look into, perhaps convert to [UInt8]
    static func messageStringToData(encodedMessage:String , encoding: EncodingFormat) throws -> Data {
        switch encoding{
        case .utf8:
            let data = encodedMessage.data(using: .utf8)!
            return data
        
        case .hex:
            let data = try dataFromHexString(encodedMessage)
            return data
        }
    }
    
    static func dataFromHexString(_ hexString: String) throws -> Data {
        let len = hexString.count
        
        // Hex strings must have an even length (two characters per byte)
        if len % 2 != 0 {throw NSError(domain: "backpackwallet", code: 404, userInfo: [NSLocalizedDescriptionKey: "bad req, length must be even"])}
        
        var data = Data(capacity: len / 2)
        var index = hexString.startIndex
        
        for _ in 0..<len / 2 {
            // Get the next two characters
            let nextIndex = hexString.index(index, offsetBy: 2)
            let byteString = String(hexString[index..<nextIndex])
            
            // Convert the two-character string into a UInt8 using radix 16 (hex)
            guard let byte = UInt8(byteString, radix: 16) else {
        
                throw NSError(domain: "BackpackWallet", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid hexadecimal sequence encountered: '\(byteString)'."])
            }
            data.append(byte)
            index = nextIndex
        }
        return data
    }
    
}
