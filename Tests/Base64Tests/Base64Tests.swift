import Testing

@testable import Base64

@Test func encodeHelloWorld() {
    let input: [UInt8] = Array("Hello World!".utf8)
    let output = Base64.encode(input)
    #expect(output == "SGVsbG8gV29ybGQh")
}

@Test func decodeHelloWorld() {
    let input = "SGVsbG8gV29ybGQh"
    let output = Base64.decode(input)
    #expect(output == Array("Hello World!".utf8))
}

@Test func encodeQuickBrownFox() {
    let input: [UInt8] = Array("The quick brown fox jumps over the lazy dog.".utf8)
    let output = Base64.encode(input)
    #expect(output == "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4=")
}

@Test func decodeQuickBrownFox() {
    let input = "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4="
    let output = Base64.decode(input)
    #expect(output == Array("The quick brown fox jumps over the lazy dog.".utf8))
}

@Test func encodeWithNumbers() {
    let input: [UInt8] = Array("123apple34".utf8)
    let output = Base64.encode(input)
    #expect(output == "MTIzYXBwbGUzNA==")
}
@Test func decodeWithNumbers() {
    let input = "MTIzYXBwbGUzNA=="
    let output = Base64.decode(input)
    #expect(output == Array("123apple34".utf8))
}

@Test func encodeEmpty() {
    let input: [UInt8] = []
    let output = Base64.encode(input)
    #expect(output == "")
}

@Test func testDecodeInvalidCharacter() {
    let invalidInput = "0OIl"  // invalid Base64 characters

    #expect(Base64.decode(invalidInput) == nil)
}
