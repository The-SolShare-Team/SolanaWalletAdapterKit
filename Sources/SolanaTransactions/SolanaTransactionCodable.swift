/// Errors that can occur when encoding or decoding Solana transactions.
///
/// These errors are thrown when reading from or writing to a `SolanaTransactionBuffer`
/// if the transaction data is malformed, incomplete, or incompatible with the expected format.
///
/// Possible Errors:
/// 1. Unexpected end of buffer
/// 2. Invalid value
/// 3. Unsupported version
public enum SolanaTransactionCodingError: Error, CustomStringConvertible {
    case endOfBuffer
    case invalidValue
    case unsupportedVersion

    public var description: String {
        switch self {
        case .endOfBuffer: "Unexpected end of buffer"
        case .invalidValue: "Invalid value"
        case .unsupportedVersion: "Unsupported version"
        }
    }
}

protocol SolanaTransactionCodable {
    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
}
