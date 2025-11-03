import Testing

@testable import Base58

@Test func encodeHelloWorld() {
    let input: [UInt8] = Array("Hello World!".utf8)
    let output = Base58.encode(input)
    #expect(output == "2NEpo7TZRRrLZSi2U")
}

@Test func decodeHelloWorld() {
    let input = "2NEpo7TZRRrLZSi2U"
    let output = Base58.decode(input)
    #expect(output == Array("Hello World!".utf8))
}

@Test func encodeQuickBrownFox() {
    let input: [UInt8] = Array("The quick brown fox jumps over the lazy dog.".utf8)
    let output = Base58.encode(input)
    #expect(output == "USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z")
}

@Test func decodeQuickBrownFox() {
    let input = "USm3fpXnKG5EUBx2ndxBDMPVciP5hGey2Jh4NDv6gmeo1LkMeiKrLJUUBk6Z"
    let output = Base58.decode(input)
    #expect(output == Array("The quick brown fox jumps over the lazy dog.".utf8))
}

@Test func encodeWithNumbers() {
    let input: [UInt8] = Array("123apple34".utf8)
    let output = Base58.encode(input)
    #expect(output == "3mJr8tDaz2NEKM")

}
@Test func decodeWithNumbers() {
    let input = "3mJr8tDaz2NEKM"
    let output = Base58.decode(input)
    #expect(output == Array("123apple34".utf8))
}

@Test func encodeEmpty() {
    let input: [UInt8] = []
    let output = Base58.encode(input)
    #expect(output == "")
}

@Test func testDecodeInvalidCharacter() {
    let invalidInput = "0OIl"  // invalid Base58 characters

    #expect(Base58.decode(invalidInput) == nil)
}
