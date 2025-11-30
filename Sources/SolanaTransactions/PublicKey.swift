import ByteBuffer
import Foundation
import SwiftBorsh

///The  address of an account, which is used to receive and send assets
///
/// The public key is a fundamental identifier for a Solana account, determining its address and enabling it to receive tokens or interact with programs.
///
/// Anyone can share their public key to receive transactions, but only the owner with the corresponding private key can access the account's funds and sign for it.
public struct PublicKey: CryptographicIdentifier, _CryptographicIdentifier {
    public static let byteLength = 32
    public let bytes: Data

    public static let zero = PublicKey(bytes: Data(repeating: 0, count: PublicKey.byteLength))
}
