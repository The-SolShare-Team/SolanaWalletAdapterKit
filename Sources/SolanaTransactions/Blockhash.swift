import ByteBuffer
import Foundation
import SwiftBorsh

/// A recent blockhash used to make a Solana transaction valid.
///
/// A `Blockhash` is a 32-byte identifier representing the hash of a recent
/// block produced by the Solana cluster.
///
/// Typically in a transaction, we use the Solana RPC client to fetch the latest blockhash and add it to our transaction. See ``getLatestBlockhash`` in `SolanaRPC`.
///
/// # Structure
/// - `byteLength`: Always **32 bytes**, matching Solana’s blockhash format.
/// - `bytes`: The raw 32-byte blockhash data.
///
/// For more information on Blockhashes, refer to [Solana Docs](https://solana.com/developers/guides/advanced/confirmation).
///

public struct Blockhash: CryptographicIdentifier, _CryptographicIdentifier {
    public static let byteLength = 32
    public let bytes: Data
}
