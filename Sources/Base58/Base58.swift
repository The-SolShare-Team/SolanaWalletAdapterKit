import Foundation

let encodingTable = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz")

extension Data {
    public func base58EncodedData() -> Data {
        let string = self.base58EncodedString()
        return Data(string.utf8)
    }

    // Based on https://pub.dev/documentation/extension_data/latest/codec/base58Encode.html
    public func base58EncodedString() -> String {
        guard !self.isEmpty else { return "" }

        let zeroes = self.firstIndex(where: { $0 != 0 }) ?? self.count
        let size = (self.count - zeroes) * 138 / 100 + 1

        var encoded = String(repeating: "1", count: zeroes)

        var buffer = [UInt8](repeating: 0, count: size)
        var length = 0

        for byte in self.dropFirst(zeroes) {
            var carry = UInt(byte)
            var i = 0
            while i < length || carry > 0 {
                carry += 256 * UInt(buffer[i])
                buffer[i] = UInt8(carry % 58)
                carry /= 58
                i += 1
            }
            length = i
        }

        encoded.reserveCapacity(length)
        for digit in buffer.prefix(length).reversed() {
            encoded.append(encodingTable[Int(digit)])
        }

        return encoded
    }

    public init?(base58Encoded input: Data) {
        guard let string = String(data: input, encoding: .utf8) else { return nil }
        self.init(base58Encoded: string)
    }

    // Based on https://pub.dev/documentation/extension_data/latest/codec/base58Decode.html
    public init?(base58Encoded input: String) {
        guard !input.isEmpty else {
            self = Data()
            return
        }

        let zeroes = input.distance(
            from: input.startIndex, to: input.firstIndex(where: { $0 != "1" }) ?? input.endIndex)
        let size = (input.count - zeroes) * 733 / 1000 + 1

        var decoded = Data(repeating: 0, count: zeroes)

        var buffer = Data(repeating: 0, count: size)
        var length = 0

        for char in input.dropFirst(zeroes) {
            guard let index = encodingTable.firstIndex(of: char) else { return nil }

            var carry = UInt(index)
            var i = 0
            while i < length || carry > 0 {
                carry += 58 * UInt(buffer[i])
                buffer[i] = UInt8(carry % 256)
                carry /= 256
                i += 1
            }
            length = i
        }

        decoded.reserveCapacity(length)
        decoded.append(contentsOf: buffer.prefix(length).reversed())

        self = decoded
    }
}
