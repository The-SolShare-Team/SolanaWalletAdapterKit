import Foundation

/// A Solana transaction is a bundle of one or more instructions that are signed and sent to the network for execution.
///
/// Each transaction includes a message containing the instructions, a list of accounts to be loaded, and a recent blockhash, along with a list of signatures to verify the sender
///
/// Transactions are the primary way to interact with the Solana network.
/// To use one, you construct a message, sign it with the necessary keys,
/// and then send the fully assembled transaction to an RPC node using SolanaRPCClient.
///
/// ```
///public init(signatures: [Signature], message: VersionedMessage) {
///     self.signatures = signatures
///     self.message = message
///}
/// ```
/// - Parameters:
///   - signatures: An array of signatures, created by signing the transaction's Message with the account's private key. See ``Signature``.
///   - message: Transaction information, including the list of instructions to be processed. See ``VersionedMessage``.
///
/// ## Methods
/// - ``encode()``
///
///   Serializes the transaction into its binary wire format, producing
///   the bytes that can be sent to the network.
public struct Transaction: Equatable, Sendable {
    public let signatures: [Signature]
    public let message: VersionedMessage

    public init(signatures: [Signature], message: VersionedMessage) {
        self.signatures = signatures
        self.message = message
    }
}

extension Transaction {
    /// Serializes the transaction into its binary wire format.
    ///
    /// This writes the transaction’s signatures followed by its message
    /// into a `SolanaTransactionBuffer` using Solana’s canonical encoding
    /// rules. The resulting bytes represent the full, signed transaction
    /// ready to be submitted to an RPC node.
    ///
    /// - Throws: `SolanaTransactionCodingError` if encoding fails.
    /// - Returns: A `Data` object containing the serialized transaction.
    public func encode() throws(SolanaTransactionCodingError) -> Data {
        var buffer = SolanaTransactionBuffer()
        try signatures.solanaTransactionEncode(to: &buffer)
        try message.solanaTransactionEncode(to: &buffer)
        return Data(buffer.readBytes(length: buffer.readableBytes) ?? [])
    }
    
    /// Creates a transaction by decoding it from its serialized byte form.
    ///
    /// This initializes a `SolanaTransactionBuffer` from the provided bytes
    /// and decodes the signatures and message in the order defined by the
    /// Solana wire format. The initializer consumes bytes from the buffer as
    /// decoding proceeds.
    ///
    /// - Parameter bytes: A sequence of bytes representing an encoded transaction.
    /// - Throws: `SolanaTransactionCodingError` if the bytes do not represent
    ///           a valid transaction or if decoding fails.
    public init<Bytes: Sequence>(bytes: Bytes) throws(SolanaTransactionCodingError)
    where Bytes.Element == UInt8 {
        var buffer = SolanaTransactionBuffer(bytes: bytes)
        signatures = try [Signature].init(fromSolanaTransaction: &buffer)
        message = try VersionedMessage(fromSolanaTransaction: &buffer)
    }
}
