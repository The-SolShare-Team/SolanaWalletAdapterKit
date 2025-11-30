import ByteBuffer
import Foundation

/// Represents a Solana transaction signature, a 64-byte cryptographic proof
/// that a transaction or message was authorized by the owner of a private key.
///
/// For more information on `Signature`, refer to [Solana Docs](https://solana.com/docs/core/transactions).
public struct Signature: CryptographicIdentifier, _CryptographicIdentifier {
    public static let byteLength = 64
    public let bytes: Data

    public static let placeholder = Signature(bytes: Data(repeating: 0, count: Signature.byteLength))
}
