import Foundation
import Testing

@testable import SolanaTransactions

/// Tests for edge cases and error handling
/// These tests verify proper handling of boundary conditions and error states

// MARK: - Buffer Edge Cases

@Test func emptyBuffer() {
    var buffer = SolanaTransactionBuffer(bytes: [])

    #expect(throws: SolanaTransactionCodingError.self) {
        try Transaction(bytes: [])
    }
}

@Test func truncatedTransaction() {
    // Transaction that ends abruptly
    let incomplete: [UInt8] = [0x01, 0x02]  // Just 2 bytes

    #expect(throws: SolanaTransactionCodingError.self) {
        try Transaction(bytes: incomplete)
    }
}

@Test func truncatedSignature() {
    // Signature count but no signature data
    let incomplete: [UInt8] = [0x01]  // 1 signature claimed but no data

    #expect(throws: SolanaTransactionCodingError.self) {
        try Transaction(bytes: incomplete)
    }
}

@Test func invalidPublicKey() {
    // Public key with wrong length
    var buffer = SolanaTransactionBuffer(bytes: [UInt8](repeating: 0, count: 16))  // only 16 bytes

    #expect(throws: SolanaTransactionCodingError.self) {
        try PublicKey(fromSolanaTransaction: &buffer)
    }
}

// MARK: - Instruction Data Edge Cases

@Test func emptyInstructionData() throws {
    let instruction = CompiledInstruction(
        programIdIndex: 0,
        accounts: [],
        data: []
    )

    var buffer = SolanaTransactionBuffer()
    try instruction.solanaTransactionEncode(to: &buffer)

    let decoded = try CompiledInstruction(fromSolanaTransaction: &buffer)
    #expect(decoded == instruction)
    #expect(decoded.data.isEmpty)
}

@Test func largeInstructionData() throws {
    // Test instruction with large data payload
    let largeData = [UInt8](repeating: 0xFF, count: 1232)  // Max instruction data size
    let instruction = CompiledInstruction(
        programIdIndex: 0,
        accounts: [0, 1, 2],
        data: largeData
    )

    var buffer = SolanaTransactionBuffer()
    try instruction.solanaTransactionEncode(to: &buffer)

    let decoded = try CompiledInstruction(fromSolanaTransaction: &buffer)
    #expect(decoded == instruction)
    #expect(decoded.data.count == 1232)
}

@Test func manyAccounts() throws {
    // Instruction with many account references
    let accounts = [UInt8](0..<32)  // 32 accounts
    let instruction = CompiledInstruction(
        programIdIndex: 0,
        accounts: accounts,
        data: [1, 2, 3]
    )

    var buffer = SolanaTransactionBuffer()
    try instruction.solanaTransactionEncode(to: &buffer)

    let decoded = try CompiledInstruction(fromSolanaTransaction: &buffer)
    #expect(decoded == instruction)
    #expect(decoded.accounts.count == 32)
}

// MARK: - Blockhash Edge Cases

@Test func blockhashEncoding() throws {
    let blockhash: Blockhash = "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk"

    var buffer = SolanaTransactionBuffer()
    try blockhash.solanaTransactionEncode(to: &buffer)

    let decoded = try Blockhash(fromSolanaTransaction: &buffer)
    #expect(decoded == blockhash)
}

@Test func allZeroBlockhash() throws {
    // Edge case: blockhash of all zeros
    let zeroBytes = [UInt8](repeating: 0, count: 32)
    let blockhash = PublicKey(bytes: zeroBytes)

    var buffer = SolanaTransactionBuffer()
    try blockhash.solanaTransactionEncode(to: &buffer)

    let decoded = try PublicKey(fromSolanaTransaction: &buffer)
    #expect(decoded == blockhash)
}

@Test func allOnesBlockhash() throws {
    // Edge case: blockhash of all 0xFF
    let onesBytes = [UInt8](repeating: 0xFF, count: 32)
    let blockhash = PublicKey(bytes: onesBytes)

    var buffer = SolanaTransactionBuffer()
    try blockhash.solanaTransactionEncode(to: &buffer)

    let decoded = try PublicKey(fromSolanaTransaction: &buffer)
    #expect(decoded == blockhash)
}

// MARK: - Signature Edge Cases

@Test func emptySignatures() throws {
    let tx = Transaction(
        signatures: [],
        message: .legacyMessage(
            LegacyMessage(
                signatureCount: 1,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 1,
                accounts: [
                    "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                    "11111111111111111111111111111111",
                ],
                blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                instructions: []
            )
        )
    )

    let encoded = try tx.encode()
    let decoded = try Transaction(bytes: encoded)

    #expect(decoded.signatures.isEmpty)
}

@Test func multipleSignatures() throws {
    let sig1 = Signature(bytes: [UInt8](repeating: 1, count: 64))
    let sig2 = Signature(bytes: [UInt8](repeating: 2, count: 64))
    let sig3 = Signature(bytes: [UInt8](repeating: 3, count: 64))

    let tx = Transaction(
        signatures: [sig1, sig2, sig3],
        message: .legacyMessage(
            LegacyMessage(
                signatureCount: 3,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 1,
                accounts: [
                    "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                    "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                    "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
                    "11111111111111111111111111111111",
                ],
                blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                instructions: []
            )
        )
    )

    let encoded = try tx.encode()
    let decoded = try Transaction(bytes: encoded)

    #expect(decoded.signatures.count == 3)
    #expect(decoded.signatures[0] == sig1)
    #expect(decoded.signatures[1] == sig2)
    #expect(decoded.signatures[2] == sig3)
}

// MARK: - UInt16 Variable Length Encoding Edge Cases

@Test func uint16MinValue() throws {
    var buffer = SolanaTransactionBuffer()
    try UInt16(0).solanaTransactionEncode(to: &buffer)

    let decoded = try UInt16(fromSolanaTransaction: &buffer)
    #expect(decoded == 0)

    // Should be encoded as single byte [0x00]
    buffer = SolanaTransactionBuffer()
    try UInt16(0).solanaTransactionEncode(to: &buffer)
    let bytes = buffer.readBytes(length: buffer.readableBytes) ?? []
    #expect(bytes == [0x00])
}

@Test func uint16MaxSingleByte() throws {
    // Max value that fits in single byte (127)
    var buffer = SolanaTransactionBuffer()
    try UInt16(127).solanaTransactionEncode(to: &buffer)

    let bytes = buffer.readBytes(length: buffer.readableBytes) ?? []
    #expect(bytes.count == 1)
    #expect(bytes == [0x7F])

    buffer = SolanaTransactionBuffer(bytes: bytes)
    let decoded = try UInt16(fromSolanaTransaction: &buffer)
    #expect(decoded == 127)
}

@Test func uint16MinTwoBytes() throws {
    // Min value that requires two bytes (128)
    var buffer = SolanaTransactionBuffer()
    try UInt16(128).solanaTransactionEncode(to: &buffer)

    let bytes = buffer.readBytes(length: buffer.readableBytes) ?? []
    #expect(bytes.count == 2)
    #expect(bytes == [0x80, 0x01])

    buffer = SolanaTransactionBuffer(bytes: bytes)
    let decoded = try UInt16(fromSolanaTransaction: &buffer)
    #expect(decoded == 128)
}

@Test func uint16MaxValue() throws {
    var buffer = SolanaTransactionBuffer()
    try UInt16.max.solanaTransactionEncode(to: &buffer)

    let decoded = try UInt16(fromSolanaTransaction: &buffer)
    #expect(decoded == UInt16.max)
}

@Test func uint16BoundaryValues() throws {
    let values: [UInt16] = [0, 1, 127, 128, 255, 256, 16383, 16384, 32767, 32768, 65535]

    for value in values {
        var buffer = SolanaTransactionBuffer()
        try value.solanaTransactionEncode(to: &buffer)
        let decoded = try UInt16(fromSolanaTransaction: &buffer)
        #expect(decoded == value)
    }
}

// MARK: - Array Encoding Edge Cases

@Test func emptyArray() throws {
    let empty: [UInt8] = []

    var buffer = SolanaTransactionBuffer()
    try empty.solanaTransactionEncode(to: &buffer)

    let decoded = try [UInt8](fromSolanaTransaction: &buffer)
    #expect(decoded.isEmpty)
}

@Test func singleElementArray() throws {
    let single: [UInt8] = [42]

    var buffer = SolanaTransactionBuffer()
    try single.solanaTransactionEncode(to: &buffer)

    let decoded = try [UInt8](fromSolanaTransaction: &buffer)
    #expect(decoded == single)
}

@Test func largeArray() throws {
    let large = [UInt8](repeating: 0xAB, count: 10000)

    var buffer = SolanaTransactionBuffer()
    try large.solanaTransactionEncode(to: &buffer)

    let decoded = try [UInt8](fromSolanaTransaction: &buffer)
    #expect(decoded.count == 10000)
    #expect(decoded == large)
}

// MARK: - Transaction Size Limits

@Test func transactionWithManyInstructions() throws {
    // Test transaction approaching instruction limit
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        for i in 0..<50 {
            SystemProgram.transfer(
                from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                lamports: Int64(i)
            )
        }
    }

    let encoded = try tx.encode()
    let decoded = try Transaction(bytes: encoded)

    switch decoded.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.count == 50)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

@Test func emptyTransaction() throws {
    // Transaction with no instructions
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        // No instructions
    }

    let encoded = try tx.encode()
    let decoded = try Transaction(bytes: encoded)

    switch decoded.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.isEmpty)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

// MARK: - Special Character and Unicode Tests

@Test func memoWithUnicode() throws {
    let instruction = MemoProgram.publishMemo(
        account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        memo: "Hello 世界 🌍"
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    let expectedMemo = "Hello 世界 🌍".utf8
    #expect(encoded.count == 4 + expectedMemo.count)
}

@Test func memoWithSpecialCharacters() throws {
    let specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
    let instruction = MemoProgram.publishMemo(
        account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        memo: specialChars
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    #expect(encoded.count == 4 + specialChars.utf8.count)
}

@Test func memoWithNewlines() throws {
    let multiline = "Line 1\nLine 2\nLine 3"
    let instruction = MemoProgram.publishMemo(
        account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        memo: multiline
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    #expect(encoded.count == 4 + multiline.utf8.count)
}

// MARK: - Program Derived Address Edge Cases

@Test func pdaValidSeeds() throws {
    let seeds: [[UInt8]] = [
        "metadata".utf8.map { $0 },
        Array("AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG".utf8),
    ]

    let programId: PublicKey = "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"

    // This should not throw for valid seeds
    let result = try? ProgramDerivedAddress.findProgramAddress(
        seeds: seeds,
        programId: programId
    )

    #expect(result != nil)
}

@Test func pdaSingleSeed() throws {
    let seeds: [[UInt8]] = [
        "singleton".utf8.map { $0 }
    ]

    let programId: PublicKey = "11111111111111111111111111111111"

    let result = try? ProgramDerivedAddress.findProgramAddress(
        seeds: seeds,
        programId: programId
    )

    #expect(result != nil)
}

@Test func pdaEmptySeed() throws {
    let seeds: [[UInt8]] = [
        []  // Empty seed
    ]

    let programId: PublicKey = "11111111111111111111111111111111"

    let result = try? ProgramDerivedAddress.findProgramAddress(
        seeds: seeds,
        programId: programId
    )

    #expect(result != nil)
}

// MARK: - CompiledInstruction Edge Cases

@Test func compiledInstructionNoAccounts() throws {
    let instruction = CompiledInstruction(
        programIdIndex: 5,
        accounts: [],
        data: [1, 2, 3, 4]
    )

    var buffer = SolanaTransactionBuffer()
    try instruction.solanaTransactionEncode(to: &buffer)

    let decoded = try CompiledInstruction(fromSolanaTransaction: &buffer)
    #expect(decoded == instruction)
    #expect(decoded.accounts.isEmpty)
}

@Test func compiledInstructionSingleAccount() throws {
    let instruction = CompiledInstruction(
        programIdIndex: 0,
        accounts: [7],
        data: []
    )

    var buffer = SolanaTransactionBuffer()
    try instruction.solanaTransactionEncode(to: &buffer)

    let decoded = try CompiledInstruction(fromSolanaTransaction: &buffer)
    #expect(decoded == instruction)
    #expect(decoded.accounts == [7])
}

// MARK: - Numeric Edge Cases for Token Operations

@Test func tokenTransferZeroAmount() throws {
    let instruction = TokenProgram.transfer(
        from: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        to: "9aZyFqQ8tGKmXMvJhq2N6zY4CjQjU3FxNGEwsM9ynWqz",
        amount: 0,
        owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    #expect(encoded[1...8] == [0, 0, 0, 0, 0, 0, 0, 0])
}

@Test func tokenTransferMaxAmount() throws {
    let instruction = TokenProgram.transfer(
        from: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        to: "9aZyFqQ8tGKmXMvJhq2N6zY4CjQjU3FxNGEwsM9ynWqz",
        amount: Int64.max,
        owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    #expect(encoded[1...8] == [255, 255, 255, 255, 255, 255, 255, 127])
}

@Test func tokenDecimalsBoundary() throws {
    // Test all valid decimal values (0-9 for SPL tokens)
    for decimals: UInt8 in 0...9 {
        let instruction = TokenProgram.initializeMint(
            mintAccount: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
            decimals: decimals,
            mintAuthority: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
        )

        var buffer = BorshByteBuffer()
        try instruction.data.borshEncode(to: &buffer)
        let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

        #expect(encoded[1] == decimals)
    }
}
