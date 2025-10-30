public enum SolanaTransactionCodingError: Error {
    case endOfBuffer
    case invalidValue
    case unsupportedVersion
}

protocol SolanaTransactionCodable {
    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
}
