import ByteBuffer
import Foundation
import SwiftBorsh

public struct Blockhash: CryptographicIdentifier, _CryptographicIdentifier {
    public static let byteLength = 32
    public let bytes: Data
}
