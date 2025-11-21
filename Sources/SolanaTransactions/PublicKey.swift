import Base58
import ByteBuffer
import Foundation
import SwiftBorsh

public struct PublicKey: CryptographicIdentifier {
    public static let byteLength = 32
    public let bytes: Data

    public static let zero = PublicKey(bytes: Data(repeating: 0, count: PublicKey.byteLength))
}
