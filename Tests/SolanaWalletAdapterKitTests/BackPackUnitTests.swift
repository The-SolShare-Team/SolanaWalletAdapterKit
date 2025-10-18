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
    @Test func testBuildURL() {
        let baseURL = "https://example.com/api"
        let queryParams: [String: String?] = [
            "id": "123",
            "sort": "date"
        ]
        
        let expectedURLString = "https://example.com/api?id=123&sort=date"
        let expectedEncodedValue = "search%20term%20%26%20user%2Bname"
        
        
        let url = Utils.buildURL(baseURL: baseURL, queryParams: queryParams)
        
        #expect(url != nil)
        let absoluteString = try? #require(url).absoluteString
        
        let expectedQuery = "q=\(expectedEncodedValue)"
        #expect(absoluteString?.contains(expectedQuery) == true)
        
        let components = URLComponents(url: try #require(url), resolvingAgainstBaseURL: false)
        let queryItemValue = components?.queryItems?.first(where: { $0.name == "q" })?.value
        
        #expect(queryItemValue == expectedEncodedValue) 
    }
}
