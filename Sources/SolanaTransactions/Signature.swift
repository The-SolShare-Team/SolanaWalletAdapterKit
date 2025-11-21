import ByteBuffer
import Foundation

public struct Signature: CryptographicIdentifier {
    static let byteLength = 64
    let bytes: Data
}
