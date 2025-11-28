import ByteBuffer
import Foundation

public struct Signature: CryptographicIdentifier, _CryptographicIdentifier {
    public static let byteLength = 64
    public let bytes: Data

    public static let placeholder = Signature(bytes: Data(repeating: 0, count: Signature.byteLength))
}
