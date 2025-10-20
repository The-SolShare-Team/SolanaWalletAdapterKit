//
//  File.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-18.
//
import Foundation
import Testing
@testable import SolanaWalletAdapterKit

@Suite("Util Tests") struct UtilTests {
    @Test func testBuildURL() throws{
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
    @Test func parseUrl() throws {
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
    
    @Test func testOnFailure() throws {
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
    
    @Test func testB58EncodeDecode() throws{
        let emptyData = Data()
        let emptyB58 = ""
        #expect(Utils.base58Encode(emptyData) == emptyB58, "Empty data should encode to empty string")
        #expect(Utils.base58Decode(emptyB58) == emptyData, "Empty string should decode to empty data")
        
        let zeroKeyRaw = Data(repeating: 0x00, count: 32)
        let zeroKeyB58 = "11111111111111111111111111111111" //verified 32 1's
        
        #expect(Utils.base58Encode(zeroKeyRaw) == zeroKeyB58, "Zero key encoding failed")
        
        let decodedZeroKeyRaw = try Utils.base58Decode(zeroKeyB58)
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
    
    
}
