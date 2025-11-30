import Foundation

public enum VersionedMessage: Equatable, Sendable {
    case legacyMessage(LegacyMessage)
    case v0(V0Message)
}

/// The original format for transaction information, used in ``Transaction``.
/// - Parameters:
///   - signatureCount:
///       The total number of signatures required for this transaction.
///       This tells Solana how many signatures to expect at the start.
///   - readOnlyAccounts:
///       The number of accounts in the account list that are read-only
///       (i.e., they are accessed but not modified).
///   - readOnlyNonSigners:
///       The number of read-only accounts that also do *not* sign the transaction.
///   - accounts:
///       The full list of accounts involved in the transaction, including
///       signers, writable accounts, and read-only accounts.
///   - blockhash:
///       The recent blockhash that makes the transaction valid.
///       This prevents the transaction from being replayed.
///   - instructions:
///       The list of compiled instructions that the transaction will execute.
///       Each instruction specifies a program and the accounts it interacts with.
///
/// ```
///public init(signatureCount: UInt8, readOnlyAccounts: UInt8, readOnlyNonSigners: UInt8, accounts: [PublicKey], blockhash: Blockhash, instructions: [CompiledInstruction]) {
///     self.signatureCount = signatureCount
///     self.readOnlyAccounts = readOnlyAccounts
///     self.readOnlyNonSigners = readOnlyNonSigners
///     self.accounts = accounts
///     self.blockhash = blockhash
///     self.instructions = instructions
///}
/// ```
public struct LegacyMessage: Equatable, Sendable {
    public let signatureCount: UInt8
    public let readOnlyAccounts: UInt8
    public let readOnlyNonSigners: UInt8
    public let accounts: [PublicKey]
    public let blockhash: Blockhash
    public let instructions: [CompiledInstruction]

    public init(signatureCount: UInt8, readOnlyAccounts: UInt8, readOnlyNonSigners: UInt8, accounts: [PublicKey], blockhash: Blockhash, instructions: [CompiledInstruction]) {
        self.signatureCount = signatureCount
        self.readOnlyAccounts = readOnlyAccounts
        self.readOnlyNonSigners = readOnlyNonSigners
        self.accounts = accounts
        self.blockhash = blockhash
        self.instructions = instructions
    }
}


/// A new versioned format for transaction message, used in ``Transaction``, that allow for additional functionality in the Solana runtime, including Address Lookup Tables.
///
/// For more information, visit [Solana Docs](https://solana.com/developers/guides/advanced/versions)
/// - Parameters:
///   - signatureCount:
///       The total number of signatures required for this transaction.
///       This tells Solana how many signatures to expect at the start.
///   - readOnlyAccounts:
///       The number of accounts in the account list that are read-only
///       (i.e., they are accessed but not modified).
///   - readOnlyNonSigners:
///       The number of read-only accounts that also do *not* sign the transaction.
///   - accounts:
///       The full list of accounts involved in the transaction, including
///       signers, writable accounts, and read-only accounts.
///   - blockhash:
///       The recent blockhash that makes the transaction valid.
///       This prevents the transaction from being replayed.
///   - addressTableLookups:
///       The list of compiled instructions that the transaction will execute.
///       Each instruction specifies a program and the accounts it interacts with.
///
/// ```
///public init(signatureCount: UInt8, readOnlyAccounts: UInt8, readOnlyNonSigners: UInt8, accounts: [PublicKey], blockhash: Blockhash, instructions: [CompiledInstruction]) {
///     self.signatureCount = signatureCount
///     self.readOnlyAccounts = readOnlyAccounts
///     self.readOnlyNonSigners = readOnlyNonSigners
///     self.accounts = accounts
///     self.blockhash = blockhash
///     self.instructions = instructions
///}
/// ```

public struct V0Message: Equatable, Sendable {
    public let signatureCount: UInt8
    public let readOnlyAccounts: UInt8
    public let readOnlyNonSigners: UInt8
    public let accounts: [PublicKey]
    public let blockhash: Blockhash
    public let instructions: [CompiledInstruction]
    public let addressTableLookups: [AddressTableLookup]

    public init(
        signatureCount: UInt8, readOnlyAccounts: UInt8, readOnlyNonSigners: UInt8,
        accounts: [PublicKey], blockhash: Blockhash, instructions: [CompiledInstruction],
        addressTableLookups: [AddressTableLookup]
    ) {
        self.signatureCount = signatureCount
        self.readOnlyAccounts = readOnlyAccounts
        self.readOnlyNonSigners = readOnlyNonSigners
        self.accounts = accounts
        self.blockhash = blockhash
        self.instructions = instructions
        self.addressTableLookups = addressTableLookups
    }
}

extension VersionedMessage: SolanaTransactionCodable {
    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        switch self {
        case .legacyMessage(let message):
            try message.solanaTransactionEncode(to: &buffer)
        case .v0(let message):
            try UInt8(0x80).solanaTransactionEncode(to: &buffer)
            try message.solanaTransactionEncode(to: &buffer)
        }
    }

    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        let mask7: UInt8 = 0x7F  // 0111 1111, mask lower 7 bits
        let firstBit: UInt8 = 0x80  // 1000 0000, continuation flag
        guard let firstByte: UInt8 = buffer.getInteger(at: buffer.readerIndex) else {
            throw .endOfBuffer
        }
        guard let version = firstByte & firstBit == 0 ? nil : firstByte & mask7 else {
            self = .legacyMessage(try LegacyMessage(fromSolanaTransaction: &buffer))
            return
        }
        buffer.moveReaderIndex(forwardBy: 1)
        self =
            switch version {
            case 0: .v0(try V0Message(fromSolanaTransaction: &buffer))
            default: throw .unsupportedVersion
            }
    }
}

extension VersionedMessage {
    /// Encodes the transaction into its serialized binary representation.
    ///
    /// This method creates a new `SolanaTransactionBuffer`, writes the
    /// transaction fields into it using `solanaTransactionEncode(to:)`,
    /// and then returns the resulting bytes as a `Data` object.
    ///
    /// - Throws: `SolanaTransactionCodingError` if any field fails to encode.
    /// - Returns: A `Data` object containing the serialized transaction bytes.
    public func encode() throws(SolanaTransactionCodingError) -> Data {
        var buffer = SolanaTransactionBuffer()
        try self.solanaTransactionEncode(to: &buffer)
        return Data(buffer.readBytes(length: buffer.readableBytes) ?? [])
    }
    
    /// Initializes a VersionedMessage by decoding it from raw serialized bytes.
    ///
    /// This creates a `SolanaTransactionBuffer` from the provided byte sequence
    /// and then initializes the transaction by consuming fields from the buffer
    /// using `init(fromSolanaTransaction:)`.
    ///
    /// - Parameter bytes: A sequence of UInt8 containing the serialized transaction.
    /// - Throws: `SolanaTransactionCodingError` if decoding fails or the
    ///           data does not represent a valid transaction.
    public init<Bytes: Sequence>(bytes: Bytes) throws(SolanaTransactionCodingError)
    where Bytes.Element == UInt8 {
        var buffer = SolanaTransactionBuffer(bytes: bytes)
        try self.init(fromSolanaTransaction: &buffer)
    }
}

extension LegacyMessage: SolanaTransactionCodable {
    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        try signatureCount.solanaTransactionEncode(to: &buffer)
        try readOnlyAccounts.solanaTransactionEncode(to: &buffer)
        try readOnlyNonSigners.solanaTransactionEncode(to: &buffer)
        try accounts.solanaTransactionEncode(to: &buffer)
        try blockhash.solanaTransactionEncode(to: &buffer)
        try instructions.solanaTransactionEncode(to: &buffer)
    }

    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        signatureCount = try UInt8(fromSolanaTransaction: &buffer)
        readOnlyAccounts = try UInt8(fromSolanaTransaction: &buffer)
        readOnlyNonSigners = try UInt8(fromSolanaTransaction: &buffer)
        accounts = try [PublicKey].init(fromSolanaTransaction: &buffer)
        blockhash = try Blockhash.init(fromSolanaTransaction: &buffer)
        instructions = try [CompiledInstruction].init(fromSolanaTransaction: &buffer)
    }
}

extension V0Message: SolanaTransactionCodable {
    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        try signatureCount.solanaTransactionEncode(to: &buffer)
        try readOnlyAccounts.solanaTransactionEncode(to: &buffer)
        try readOnlyNonSigners.solanaTransactionEncode(to: &buffer)
        try accounts.solanaTransactionEncode(to: &buffer)
        try blockhash.solanaTransactionEncode(to: &buffer)
        try instructions.solanaTransactionEncode(to: &buffer)
        try addressTableLookups.solanaTransactionEncode(to: &buffer)
    }

    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        signatureCount = try UInt8(fromSolanaTransaction: &buffer)
        readOnlyAccounts = try UInt8(fromSolanaTransaction: &buffer)
        readOnlyNonSigners = try UInt8(fromSolanaTransaction: &buffer)
        accounts = try [PublicKey].init(fromSolanaTransaction: &buffer)
        blockhash = try Blockhash.init(fromSolanaTransaction: &buffer)
        instructions = try [CompiledInstruction].init(fromSolanaTransaction: &buffer)
        addressTableLookups = try [AddressTableLookup].init(fromSolanaTransaction: &buffer)
    }
}
