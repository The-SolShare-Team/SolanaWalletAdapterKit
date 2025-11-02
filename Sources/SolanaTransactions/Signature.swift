import ByteBuffer

public struct Signature: CryptographicIdentifier {
    static let byteLength = 64
    let bytes: [UInt8]
}
