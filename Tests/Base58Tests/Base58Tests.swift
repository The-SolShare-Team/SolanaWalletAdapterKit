import Foundation
import Testing

@testable import Base58

@Test func encodeHelloWorld() {
    let input = Data("Hello World!".utf8)
    let output = input.base58EncodedString()
    #expect(output == "2NEpo7TZRRrLZSi2U")
}

@Test func decodeHelloWorld() {
    let input = "2NEpo7TZRRrLZSi2U"
    let output = Data(base58Encoded: input)
    #expect(output == Data("Hello World!".utf8))
}

@Test func encodeQuickBrownFox() {
    let input = Data("The quick brown fox jumps over the lazy dog.".utf8)
    let output = input.base58EncodedString()
    #expect(output == "USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z")
}

@Test func decodeQuickBrownFox() {
    let input = "USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z"
    let output = Data(base58Encoded: input)
    #expect(output == Data("The quick brown fox jumps over the lazy dog.".utf8))
}

@Test func encodeWithNumbers() {
    let input = Data("123apple34".utf8)
    let output = input.base58EncodedString()
    #expect(output == "3mJr8tDaz2NEKM")

}
@Test func decodeWithNumbers() {
    let input = "3mJr8tDaz2NEKM"
    let output = Data(base58Encoded: input)
    #expect(output == Data("123apple34".utf8))
}

@Test func encodeEmpty() {
    let input = Data()
    let output = input.base58EncodedString()
    #expect(output == "")
}

@Test func decodeEmpty() {
    let input = ""
    let output = Data(base58Encoded: input)
    #expect(output == Data())
}

@Test func testDecodeInvalidCharacter() {
    let invalidInput = "0OIl"  // invalid Base58 characters
    #expect(Data(base58Encoded: invalidInput) == nil)
}

@Test func encodeData() {
    let input = Data([0, 255, 128, 64, 32, 16, 8, 4, 2, 1])
    #expect(input.base58EncodedString() == String(bytes: input.base58EncodedData(), encoding: .utf8))
}

@Test func decodeData() {
    let input = "1cWB"
    #expect(Data(base58Encoded: input) == Data(base58Encoded: Data(input.utf8)))
}
