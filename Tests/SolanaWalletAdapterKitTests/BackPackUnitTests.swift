//
//  File.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-18.
//
import Foundation
import Testing
import CryptoKit
@testable import SolanaWalletAdapterKit

@Suite("Util Tests") struct UtilTests {
    @Test func testBuildURL() async throws{
        let baseURL = "https://example.com/api"
        let unencodedQueryValue = "search term & user+name"
        let queryParams: [String: String?] = [
            "id": "123",
            "sort": "date",
            "encoded": unencodedQueryValue
        ]
        
        let expectedEncodedValue = "search%20term%20%26%20user+name"
        
        
        let url = Utils.buildURL(baseURL: baseURL, queryParams: queryParams)
        let unwrappedURL = try #require(url)
        let absoluteString = unwrappedURL.absoluteString
        
        #expect(absoluteString.contains("encoded=\(expectedEncodedValue)"))
        let components = URLComponents(url: unwrappedURL, resolvingAgainstBaseURL: false)
        let queryItems = try #require(components?.queryItems)
        let complexQueryItem = try #require(queryItems.first(where: { $0.name == "encoded" }))
        #expect(complexQueryItem.value == unencodedQueryValue)
        let idItem = try #require(queryItems.first(where: { $0.name == "id" }))
        #expect(idItem.value == "123")
    }
    @Test func parseUrl() async throws {
        let url = URL(string: "https://example.com/callback?param1=value1&param2=value2&param3=")!
        let parsed = Utils.parseUrl(url)
        
        #expect(parsed["param1"] == "value1", "param1 should be parsed correctly")
        #expect(parsed["param2"] == "value2", "param2 should be parsed correctly")
        #expect(parsed["param3"] == "", "param3 with empty value should not appear")
        
        // URL with no query
        let emptyUrl = URL(string: "https://example.com/path")!
        let parsedEmpty = Utils.parseUrl(emptyUrl)
        #expect(parsedEmpty.isEmpty, "URL with no query should return empty dictionary")
        
        // URL with all empty values
        let emptyValuesUrl = URL(string: "https://example.com/callback?param1=&param2=")!
        let parsedEmptyValues = Utils.parseUrl(emptyValuesUrl)
        #expect(parsedEmptyValues["param1"] == "" && parsedEmptyValues["param2"] == "", "URL with only empty values should return empty dictionary")
    }
    
    @Test func testOnFailure() async throws {
        let payloadWithError = ["errorCode": "123", "errorMessage": "Something went wrong"]
        do {
            try Utils.onFailure(payloadWithError)
            #expect(Bool(false), "Expected onFailure to throw an error")
        } catch let error as NSError {
            #expect(error.domain == "BackpackWallet", "Error domain should be BackpackWallet")
            #expect(error.code == 1, "Error code should be 1")
            #expect(error.localizedDescription == "Failure to connect -- Error 123: Something went wrong", "Error message mismatch")
        }

        // Case: payload missing errorCode or errorMessage
        let payloadNoError = ["errorCode": "123"]
        do {
            try Utils.onFailure(payloadNoError)
            #expect(true, "Should not throw when errorCode or errorMessage is missing")
        } catch {
            #expect(Bool(false), "Should not throw for incomplete payload")
        }
    }
    
    @Test func testGenerateNonce() {
        let nonceLength = 24
        let nonce = Utils.generateNonce(nonceLength)
        
        #expect(nonce.count == nonceLength, "Nonce should be exactly \(nonceLength) bytes")
        let allZeros = Data(repeating: 0, count: nonceLength)
        #expect(nonce != allZeros, "Nonce should not be all zeros")
        let nonce2 = Utils.generateNonce(nonceLength)
        #expect(nonce != nonce2, "Nonce should be unique for each call")
    }
    
    @Test func testB58EncodeDecode() async throws{
        let emptyData = Data()
        let emptyB58 = ""
        #expect(Utils.base58Encode(emptyData) == emptyB58, "Empty data should encode to empty string")
        #expect(Utils.base58Decode(emptyB58) == emptyData, "Empty string should decode to empty data")
        
        let zeroKeyRaw = Data(repeating: 0x00, count: 32)
        let zeroKeyB58 = "11111111111111111111111111111111" //verified 32 1's
        
        #expect(Utils.base58Encode(zeroKeyRaw) == zeroKeyB58, "Zero key encoding failed")
        
        let decodedZeroKeyRaw = Utils.base58Decode(zeroKeyB58)
        #expect(decodedZeroKeyRaw == zeroKeyRaw, "Zero key decoding failed")
        
        let invalidB58 = "Invalid$String!"
        
        #expect(Utils.base58Decode(invalidB58) == Data(), "Invalid Base58 string should decode to nil")
        
        
        let alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
        let alphabetData = Data(alphabet.utf8)
        let alphabetB58 = "SxQSv8AWonnsWRyFyqRoAk1kUMEC2Xz7Q9UVuUhunVEat1Axfb3YAZRqeR1QtxBTdsnvtWzzKmidgUq"
        
        let encodedReadable = Utils.base58Encode(alphabetData )
        #expect(encodedReadable == alphabetB58, "Printable ASCII failed")
        
        let decodedReadable = Utils.base58Decode(encodedReadable)
        let decodedStr = String(data: decodedReadable, encoding: .utf8)

        #expect(decodedStr == alphabet, "Printable ASCII failed")
    }
    
    @Test func testComputeSharedKey() async throws {
        let dappPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let dappPublicKey = dappPrivateKey.publicKey
            
        let walletPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let walletPublicKey = walletPrivateKey.publicKey
        
        let dappSideKey = try Utils.computeSharedKey(walletEncPubKeyB58: Utils.base58Encode(walletPublicKey.rawRepresentation), dappEncryptionPrivateKey: dappPrivateKey)
        let walletSideKey = try Utils.computeSharedKey(walletEncPubKeyB58: Utils.base58Encode(dappPublicKey.rawRepresentation), dappEncryptionPrivateKey: walletPrivateKey)
        
        #expect(dappSideKey == walletSideKey, "symmetric key should be the same")
        
    }
    
    @Test func testEncryptDecryptPayload() async throws {
        var payload = ["msg": "hello world", "id": "123"]
        var nonce = Utils.base58Encode(Utils.generateNonce()) // 24-byte base58 encoded nonce
        
        let sharedKeyData = Data(repeating: 42, count: 32)
        let sharedKey = SymmetricKey(data: sharedKeyData)
        
        var encrypted = try Utils.encryptPayload(sharedKey: sharedKey, payload: payload, nonce: nonce)
        #expect(!encrypted.isEmpty)
        
        let decrypted = try Utils.decryptPayload(encryptedDataB58: encrypted, nonceB58: nonce, sharedKey: sharedKey)
        #expect(decrypted["msg"] as? String == "hello world")
        #expect(decrypted["id"] as? String == "123")
        
        //different nonce -> different cipher text
        payload = ["a": "b"]
        var key = SymmetricKey(data: Data(repeating: 7, count: 32))
        let nonce1 = Utils.base58Encode(Utils.generateNonce())
        let nonce2 = Utils.base58Encode(Utils.generateNonce())
        
        let encrypted1 = try Utils.encryptPayload(sharedKey: key, payload: payload, nonce: nonce1)
        let encrypted2 = try Utils.encryptPayload(sharedKey: key, payload: payload, nonce: nonce2)

        #expect(encrypted1 != encrypted2)
        
        //tampered cipher test -> fails
        payload = ["x": "y"]
        key = SymmetricKey(data: Data(repeating: 1, count: 32))
        nonce = Utils.base58Encode(Utils.generateNonce()) 

        encrypted = try Utils.encryptPayload(sharedKey: key, payload: payload, nonce: nonce)
        encrypted.removeLast() // tamper ciphertext

        do {
            _ = try Utils.decryptPayload(encryptedDataB58: encrypted, nonceB58: nonce, sharedKey: key)
            Issue.record("Expected decryption to fail for tampered ciphertext")
        } catch {
            #expect(true) // expected error
        }

    }
    
    @Test func testMessageStringToData() async throws{
        let utf8Message = "Hello, 🌎!"
        var data = try Utils.messageStringToData(encodedMessage: utf8Message, encoding: .utf8)
        let roundTrip = String(data: data, encoding: .utf8)
        #expect(roundTrip == utf8Message)
        
        data = try Utils.messageStringToData(encodedMessage: "", encoding: .utf8)
        #expect(data.isEmpty)
        
        var hex = "48656C6C6F" // "Hello"
        data = try Utils.messageStringToData(encodedMessage: hex, encoding: .hex)
        var str = String(data: data, encoding: .utf8)
        #expect(str == "Hello")
        
        hex = "68656c6c6f" // "hello"
        data = try Utils.messageStringToData(encodedMessage: hex, encoding: .hex)
        str = String(data: data, encoding: .utf8)
        #expect(str == "hello")
        
        hex = ""
        data = try Utils.messageStringToData(encodedMessage: hex, encoding: .hex)
        #expect(data.isEmpty)
        
        let invalidHex = "GG"
        do {
            _ = try Utils.messageStringToData(encodedMessage: invalidHex, encoding: .hex)
            Issue.record("Should have thrown for invalid hex characters")
        } catch {
            #expect(error.localizedDescription.contains("Invalid hexadecimal sequence"))
        }
        
        let oddHex = "ABC" // odd length → assertion
        #expect {
            _ = try Utils.messageStringToData(encodedMessage: oddHex, encoding: .hex)
        } throws: { _ in true }
    }
}


@Suite("Backpack Wallet Provider Functions Test") struct BackpackWalletTests {
    @Test func testInit() async throws {
        // init with private key
        let existingPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let wallet = try BackpackWallet(privateKey: existingPrivateKey)
        
        //NOTE: before making private key a private class attribute, white box testing was done to ensure private key behaves as expected
        
        #expect(wallet.getDappEncryptionPrivateKey().rawRepresentation == existingPrivateKey.rawRepresentation)
        #expect(wallet.dappEncryptionPublicKey.rawRepresentation == existingPrivateKey.publicKey.rawRepresentation)
        #expect(wallet.isConnected == false)
        #expect(wallet.session == nil)
        #expect(wallet.dappEncryptionSharedKey == nil)
        
        //init without private key
        let wallet1 = try BackpackWallet()
        let wallet2 = try BackpackWallet()

        #expect(wallet1.getDappEncryptionPrivateKey().rawRepresentation.count == 32)
        #expect(wallet1.dappEncryptionPublicKey.rawRepresentation.count == 32)
        #expect(wallet1.isConnected == false)
        #expect(wallet1.session == nil)
        #expect(wallet1.dappEncryptionSharedKey == nil)

        // Two new wallets should have different private keys
        #expect(wallet1.getDappEncryptionPrivateKey().rawRepresentation != wallet2.getDappEncryptionPrivateKey().rawRepresentation)
        
//        just testing publickey is good
        let wallet3 = try BackpackWallet(privateKey: nil)
        let derivedPub = wallet3.getDappEncryptionPrivateKey().publicKey
        #expect(derivedPub.rawRepresentation == wallet3.getDappEncryptionPrivateKey().publicKey.rawRepresentation)
    }
    
    public var wallet: BackpackWallet!
    
    init() async throws {
        wallet = try? BackpackWallet()
    }
    
    @Test func testHandleRedirect() async throws {
        // Simulate a URL with query params
        let url = URL(string: "https://callback?userPublicKey=testUser&session=abc123&nonce=nonce1&encryptionPublicKey=key123")!
        let response = try await wallet.handleRedirect(url) { params in
            return ConnectResponse(
                encryptionPublicKey: Data(params["encryptionPublicKey"]!.utf8),
                userPublicKey: params["userPublicKey"]!,
                session: params["session"]!,
                nonce: params["nonce"]!
            )
        }
        #expect(response.userPublicKey == "testUser")
        #expect(response.session == "abc123")
        #expect(response.nonce == "nonce1")
        #expect(String(data: response.encryptionPublicKey, encoding: .utf8) == "key123")

        // MARK: - Failure Case (Wallet error)
        
        let failUrl = URL(string: "https://callback?errorCode=404&errorMessage=NotFound")!
                
        do {
            _ = try await wallet.handleRedirect(failUrl) { params in
                Issue.record("Success handler should not be called")
                return ConnectResponse(
                    encryptionPublicKey: Data(),
                    userPublicKey: "",
                    session: "",
                    nonce: ""
                )
            }
            Issue.record("Expected error was not thrown")
        } catch let error as NSError {
            #expect(error.domain == "BackpackWallet")
            #expect(error.localizedDescription.contains("Failure to connect"))
        }
        
        // Missing params - throw error
        
        let incompUrl = URL(string: "https://callback?userPublicKey=onlyone")!
                
        do {
            _ = try await wallet.handleRedirect(incompUrl) { params in
                guard let nonce = params["nonce"] else {
                    throw NSError(domain: "Test", code: 1)
                }
                return ConnectResponse(
                    encryptionPublicKey: Data(),
                    userPublicKey: params["userPublicKey"]!,
                    session: "",
                    nonce: nonce
                )
            }
            Issue.record("Expected missing param error not thrown")
        } catch {
            #expect(true)
        }
        
        // GIVEN: A mock successful URL and a handler for Void
        let voidUrl = URL(string: "https://callback?a=b")!
        var successCheck = false // Flag to ensure handler runs
        
        try await wallet.handleRedirect(voidUrl) { params in
            #expect(params["a"] == "b") // params still passed
            successCheck = true
        }
        try #require(successCheck) // make sure the callback is called regardless of void return type
    }
    
    //Rest of the functions involve universal links, will be testing with UI tests using XCTests, not unit tests
}
