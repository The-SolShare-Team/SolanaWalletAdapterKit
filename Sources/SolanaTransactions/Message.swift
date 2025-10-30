public enum CompiledVersionedMessage: Equatable {
    case legacyMessage(CompiledLegacyMessage)
    case v0(CompiledV0Message)
}

public struct CompiledLegacyMessage: Equatable {
    let signatureCount: UInt8
    let readOnlyAccounts: UInt8
    let readOnlyNonSigners: UInt8
    let accounts: [PublicKey]
    let blockhash: Blockhash
    let instructions: [CompiledInstruction]
}

public struct CompiledV0Message: Equatable {
    let signatureCount: UInt8
    let readOnlyAccounts: UInt8
    let readOnlyNonSigners: UInt8
    let accounts: [PublicKey]
    let blockhash: Blockhash
    let instructions: [CompiledInstruction]
    let addressTableLookups: [CompiledAddressTableLookup]
}

extension CompiledVersionedMessage: SolanaTransactionCodable {
    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        switch self {
        case .legacyMessage(let message):
            try message.solanaTransactionEncode(to: &buffer)
        case .v0(let message):
            try UInt8(0).solanaTransactionEncode(to: &buffer)
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
            self = .legacyMessage(try CompiledLegacyMessage(fromSolanaTransaction: &buffer))
            return
        }
        buffer.moveReaderIndex(forwardBy: 1)
        self =
            switch version {
            case 0: .v0(try CompiledV0Message(fromSolanaTransaction: &buffer))
            default: throw .unsupportedVersion
            }
    }
}

extension CompiledLegacyMessage: SolanaTransactionCodable {
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

extension CompiledV0Message: SolanaTransactionCodable {
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
        addressTableLookups = try [CompiledAddressTableLookup].init(fromSolanaTransaction: &buffer)
    }
}
