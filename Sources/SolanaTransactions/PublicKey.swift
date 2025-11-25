import ByteBuffer
import Foundation
import SwiftBorsh

public struct PublicKey: CryptographicIdentifier, _CryptographicIdentifier {
    public static let byteLength = 32
    public let bytes: Data
    public init(bytes: Data) {
        self.bytes = bytes
    }
    
    public static let zero = PublicKey(bytes: Data(repeating: 0, count: PublicKey.byteLength))
}


