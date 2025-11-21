import Base58
import Foundation
import Testing

@testable import Salt

@Test func noFatalError() {
    #expect(
        try! !SaltUtil.isOnCurve(
            publicKey: Data([
                1, 2, 3, 4, 5, 6, 7, 8,
                9, 10, 11, 12, 13, 14, 15, 16,
                17, 18, 19, 20, 21, 22, 23, 24,
                25, 26, 27, 28, 29, 30, 31, 32,
            ])))
}

@Test func offCurve() {
    #expect(
        try! !SaltUtil.isOnCurve(
            publicKey: Data(base58Encoded: "616dEZzzvT4QX9oe8rDoNGi7AVjyXuSEDyosz5uXWN1K")!))
}

@Test func onCurve() {
    #expect(
        try! SaltUtil.isOnCurve(
            publicKey: Data(base58Encoded: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG")!))
}
