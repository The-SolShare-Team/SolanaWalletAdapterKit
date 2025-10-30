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
