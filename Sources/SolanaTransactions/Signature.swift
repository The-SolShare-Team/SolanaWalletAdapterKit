import ByteBuffer
import Foundation

public struct Signature: CryptographicIdentifier, _CryptographicIdentifier {
    public static let byteLength = 64
    public let bytes: Data
}
