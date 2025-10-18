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
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                queryItems.append(URLQueryItem(name: key, value: encodedValue))
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
    static private let BASE58_ALPHABET_BYTES = [UInt8](BASE58_ALPHABET.utf8)
    
    static func base58Encode(_ data: Data) -> String {
        let bytes = [UInt8](data)
            if bytes.isEmpty { return "" }

            // Count leading zeros
            var zeros = 0
            for byte in bytes {
                if byte == 0 {
                    zeros += 1
                } else {
                    break
                }
            }

            var b58: [UInt8] = [] // Resulting Base58 characters
            var input = bytes // Mutable copy of input bytes

            while input.count > 0 {
                var carry = 0
                var i = 0
                // Perform long division by 58
                while i < input.count {
                    let val = Int(input[i]) + carry * 256 // Treat input[i] as part of a larger number
                    input[i] = UInt8(val / 58)           // Store quotient
                    carry = val % 58                     // Store remainder as carry
                    i += 1
                }

                if carry > 0 {
                    // Prepend remainder to result
                    b58.insert(BASE58_ALPHABET_BYTES[carry], at: 0)
                }

                // Remove leading zeros from the processed input
                var newLength = input.count
                while newLength > 0 && input[0] == 0 {
                    input.remove(at: 0)
                    newLength -= 1
                }
            }

            // Add back original leading zeros (which become '1's in Base58)
            for _ in 0..<zeros {
                b58.insert(BASE58_ALPHABET_BYTES[0], at: 0) // '1' character for zero
            }

            return String(bytes: b58, encoding: .utf8) ?? ""
    }
    
    // Function to decode Base58 String to Data
    //AI Generated
    static func base58Decode(_ base58String: String) -> Data? {
        if base58String.isEmpty { return Data() }

        let b58 = [UInt8](base58String.utf8)
        
        // Count leading '1's (which represent zero bytes)
        var zeros = 0
        for byte in b58 {
            if byte == BASE58_ALPHABET_BYTES[0] { // '1' character
                zeros += 1
            } else {
                break
            }
        }

        var decodedBytes: [UInt8] = [] // Resulting raw bytes
        for char in b58 {
            guard let index = BASE58_ALPHABET_BYTES.firstIndex(of: char) else { return nil } // Invalid Base58 character

            var carry = index
            // Perform long multiplication by 58 and add current digit
            for i in 0..<decodedBytes.count {
                let val = Int(decodedBytes[i]) * 58 + carry
                decodedBytes[i] = UInt8(val % 256)
                carry = val / 256
            }

            while carry > 0 {
                decodedBytes.append(UInt8(carry % 256))
                carry /= 256
            }
        }

        decodedBytes.reverse() // Digits were appended in reverse order

        // Remove leading zeros from the result
        var newLength = decodedBytes.count
        while newLength > 0 && decodedBytes[0] == 0 {
            decodedBytes.remove(at: 0)
            newLength -= 1
        }

        // Add back original leading zeros
        for _ in 0..<zeros {
            decodedBytes.insert(0, at: 0)
        }

        return Data(decodedBytes)
    }
    
    // need to cross reference with tweetnacl implementation to see byte sizes that work as well as wallet docs
    // https://github.com/bitmark-inc/tweetnacl-swiftwrap/tree/master/Sources/TweetNacl
    
    static func computeSharedKey(walletEncPubKeyB58: String, encryptedDataB58: String, nonceB58: String, dappEncryptionPrivateKey: Box.KeyPair.PrivateKey  /*Curve25519.KeyAgreement.PrivateKey*/) throws -> Data /*SymmetricKey */{
        guard let walletPubKeyData = Utils.base58Decode(walletEncPubKeyB58) else {
            throw NSError(domain: "Utils", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid wallet public key"])
        }
        let sharedKey = try Box.sharedKey(
            privateKey: dappEncryptionPrivateKey,
            publicKey: walletPubKeyData
        )
        return sharedKey
        
//        guard let walletEncryptionPubKeyData = Utils.base58Decode(walletEncPubKeyB58),
//            let dataDecoded = Utils.base58Decode(encryptedDataB58),
//            let nonceData = Utils.base58Decode(nonceB58) else {
//                print("invalid data, nonce, or key")
//                return SymmetricKey(size: .bits256)
//            }
//        let backpackPublicKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: walletEncryptionPubKeyData)
//        let dappEncryptionSharedSecret = try dappEncryptionPrivateKey.sharedSecretFromKeyAgreement(with: backpackPublicKey)
//        //decipher the data for use
//        return dappEncryptionSharedSecret.hkdfDerivedSymmetricKey(
//            using: SHA256.self,
//            salt: Data(),
//            sharedInfo: Data(),
//            outputByteCount: 32)
    }
    
    // base58 decoded and decrypted using shared secret generated symmetric key
    static func decryptPayload(encryptedDataB58: String, nonceB58: String, sharedKey: Data /*symmetricKey: SymmetricKey*/)
    throws -> [String: String]{
        var data: [String: String] = [:]
        guard let dataDecoded = Utils.base58Decode(encryptedDataB58),
              let nonceData = Utils.base58Decode(nonceB58) else {
            print("Error decoding from base58")
            return data
        }
        let message = try SecretBox.open(
                    ciphertext: dataDecoded,
                    nonce: nonceData,
                    key: sharedKey
        )
            
//        let nonce = try ChaChaPoly.Nonce(data: nonceData)
//        let sealedBox = try ChaChaPoly.SealedBox(
//            nonce: nonce,
//            ciphertext: dataDecoded.dropLast(16), // ciphertext
//            tag: dataDecoded.suffix(16) // authentication tag (16 bytes, length might be incorrect)
//        )
//        let message = try ChaChaPoly.open(sealedBox, using: symmetricKey)
        data = try JSONSerialization.jsonObject(with: message, options: []) as! [String: String]
            
        
        return data
    }
    
    static func encryptBackpackData(data: Data, nonce: Data, sharedKey: Data/*symmetricKey: SymmetricKey*/) throws -> String {
//        // Encrypt the data
//        let sealedBox = try ChaChaPoly.seal(data, using: symmetricKey, nonce: nonce)
//        
//        // Concatenate ciphertext + tag (same format as your decrypt function expects)
//        var combined = sealedBox.ciphertext
//        combined.append(contentsOf: sealedBox.tag)
//        
//        // Base58 encode the result
//        let encoded = Utils.base58Encode(combined)
//        return encoded
        let encrypted = try SecretBox.seal(
                    message: data,
                    nonce: nonce,
                    key: sharedKey
                )
        return encrypted
    }
    // encrypted, base58 encoded
    static func encryptPayload( sharedKey: Data, payload: [String:String], nonce: String) throws -> String {
        let payloadJson = try JSONSerialization.data(withJSONObject: payload)
        let encryptedPayload = try Utils.encryptBackpackData(data: payloadJson, nonce: Utils.base58Decode(nonce)!, sharedKey: sharedKey)
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
            let data = dataFromHexString(encodedMessage)
            return data
        }
    }
    
    public static func dataFromHexString(_ hexString: String) throws -> Data {
        let len = hexString.count
        
        // Hex strings must have an even length (two characters per byte)
        assert(len % 2 == 0)
        
        var data = Data(capacity: len / 2)
        var index = hexString.startIndex
        
        for _ in 0..<len / 2 {
            // Get the next two characters
            let nextIndex = hexString.index(index, offsetBy: 2)
            let byteString = String(hexString[index..<nextIndex])
            
            // Convert the two-character string into a UInt8 using radix 16 (hex)
            guard let byte = UInt8(byteString, radix: 16) else {
                throw BackpackError.encodingFailed("Invalid hexadecimal sequence encountered: '\(byteString)'.")
            }
            data.append(byte)
            index = nextIndex
        }
        return data
    }
}
