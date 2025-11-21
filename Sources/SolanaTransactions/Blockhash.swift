import Base58
import ByteBuffer
import Foundation
import SwiftBorsh

public struct Blockhash: CryptographicIdentifier {
    public static let byteLength = 32
    public let bytes: Data
}
