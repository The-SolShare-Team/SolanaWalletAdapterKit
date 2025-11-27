public enum VersionedMessage: Equatable, Sendable {
    case legacyMessage(LegacyMessage)
    case v0(V0Message)
}

public struct LegacyMessage: Equatable, Sendable {
    let signatureCount: UInt8
    let readOnlyAccounts: UInt8
    let readOnlyNonSigners: UInt8
    let accounts: [PublicKey]
    let blockhash: Blockhash
    let instructions: [CompiledInstruction]

    public init(signatureCount: UInt8, readOnlyAccounts: UInt8, readOnlyNonSigners: UInt8, accounts: [PublicKey], blockhash: Blockhash, instructions: [CompiledInstruction]) {
        self.signatureCount = signatureCount
        self.readOnlyAccounts = readOnlyAccounts
        self.readOnlyNonSigners = readOnlyNonSigners
        self.accounts = accounts
        self.blockhash = blockhash
        self.instructions = instructions
    }
}

public struct V0Message: Equatable, Sendable {
    let signatureCount: UInt8
    let readOnlyAccounts: UInt8
    let readOnlyNonSigners: UInt8
    let accounts: [PublicKey]
    let blockhash: Blockhash
    let instructions: [CompiledInstruction]
    let addressTableLookups: [AddressTableLookup]

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
