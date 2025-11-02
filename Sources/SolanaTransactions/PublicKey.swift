import Base58
import ByteBuffer
import SwiftBorsh

public struct PublicKey: CryptographicIdentifier {
    public static let byteLength = 32
    public let bytes: [UInt8]

    public static let zero = PublicKey(bytes: [UInt8](repeating: 0, count: PublicKey.byteLength))
}
