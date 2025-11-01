import Foundation
import Testing

@testable import SolanaTransactions

/// Tests for different message formats (Legacy vs V0)
/// These tests verify proper encoding/decoding of both message types

// MARK: - Legacy Message Tests

@Test func legacyMessageEncoding() throws {
    let message = LegacyMessage(
        signatureCount: 1,
        readOnlyAccounts: 0,
        readOnlyNonSigners: 1,
        accounts: [
            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            "11111111111111111111111111111111",
        ],
        blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
        instructions: [
            CompiledInstruction(
                programIdIndex: 2,
                accounts: [0, 1],
                data: [2, 0, 0, 0, 128, 150, 152, 0, 0, 0, 0, 0]
            )
        ]
    )

    var buffer = SolanaTransactionBuffer()
    try message.solanaTransactionEncode(to: &buffer)

    let decoded = try LegacyMessage(fromSolanaTransaction: &buffer)
    #expect(decoded == message)
}

@Test func legacyMessageInTransaction() throws {
    let tx = Transaction(
        signatures: [],
        message: .legacyMessage(
            LegacyMessage(
                signatureCount: 1,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 0,
                accounts: [
                    "11111111111111111111111111111111",
                    "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                    "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                ],
                blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                instructions: [
                    CompiledInstruction(
                        programIdIndex: 0,
                        accounts: [1, 2],
                        data: [2, 0, 0, 0, 0, 16, 39, 0, 0, 0, 0, 0]
                    )
                ]
            )
        )
    )

    let encoded = try tx.encode()
    let decoded = try Transaction(bytes: encoded)

    #expect(decoded == tx)
}

// MARK: - V0 Message Tests

@Test func v0MessageEncoding() throws {
    let message = V0Message(
        signatureCount: 1,
        readOnlyAccounts: 0,
        readOnlyNonSigners: 1,
        accounts: [
            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            "11111111111111111111111111111111",
        ],
        blockhash: "DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj",
        instructions: [
            CompiledInstruction(
                programIdIndex: 2,
                accounts: [0, 1],
                data: [2, 0, 0, 0, 128, 150, 152, 0, 0, 0, 0, 0]
            )
        ],
        addressTableLookups: []
    )

    var buffer = SolanaTransactionBuffer()
    try message.solanaTransactionEncode(to: &buffer)

    let decoded = try V0Message(fromSolanaTransaction: &buffer)
    #expect(decoded == message)
}

@Test func v0MessageInTransaction() throws {
    let tx = Transaction(
        signatures: [],
        message: .v0(
            V0Message(
                signatureCount: 1,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 1,
                accounts: [
                    "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                    "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                    "11111111111111111111111111111111",
                ],
                blockhash: "DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj",
                instructions: [
                    CompiledInstruction(
                        programIdIndex: 2,
                        accounts: [0, 1],
                        data: [2, 0, 0, 0, 128, 150, 152, 0, 0, 0, 0, 0]
                    )
                ],
                addressTableLookups: []
            )
        )
    )

    let encoded = try tx.encode()
    let decoded = try Transaction(bytes: encoded)

    #expect(decoded == tx)
}

@Test func v0MessageVersionPrefix() throws {
    // V0 messages should have 0x80 prefix (version 0 with high bit set)
    let tx = Transaction(
        signatures: [],
        message: .v0(
            V0Message(
                signatureCount: 1,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 1,
                accounts: [
                    "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                    "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                    "11111111111111111111111111111111",
                ],
                blockhash: "DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj",
                instructions: [],
                addressTableLookups: []
            )
        )
    )

    let encoded = try tx.encode()

    // First byte should be 0 (no signatures), then version byte 0x80
    #expect(encoded[0] == 0)  // no signatures
    #expect(encoded[1] == 0x80)  // version 0 with high bit set
}

@Test func legacyMessageNoVersionPrefix() throws {
    // Legacy messages should NOT have a version prefix
    let tx = Transaction(
        signatures: [],
        message: .legacyMessage(
            LegacyMessage(
                signatureCount: 1,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 1,
                accounts: [
                    "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                    "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                    "11111111111111111111111111111111",
                ],
                blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                instructions: []
            )
        )
    )

    let encoded = try tx.encode()

    // First byte should be 0 (no signatures), second byte should be signature count (1)
    #expect(encoded[0] == 0)  // no signatures
    #expect(encoded[1] == 1)  // signature count (no version byte)
}

// MARK: - Address Table Lookup Tests

@Test func v0WithAddressTableLookup() throws {
    let lookup = AddressTableLookup(
        account: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        writableIndexes: [0, 1, 2],
        readOnlyIndexes: [3, 4]
    )

    let message = V0Message(
        signatureCount: 1,
        readOnlyAccounts: 0,
        readOnlyNonSigners: 1,
        accounts: [
            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            "11111111111111111111111111111111",
        ],
        blockhash: "DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj",
        instructions: [],
        addressTableLookups: [lookup]
    )

    var buffer = SolanaTransactionBuffer()
    try message.solanaTransactionEncode(to: &buffer)

    let decoded = try V0Message(fromSolanaTransaction: &buffer)
    #expect(decoded == message)
    #expect(decoded.addressTableLookups.count == 1)
    #expect(decoded.addressTableLookups[0].writableIndexes == [0, 1, 2])
    #expect(decoded.addressTableLookups[0].readOnlyIndexes == [3, 4])
}

@Test func v0WithMultipleAddressTableLookups() throws {
    let lookup1 = AddressTableLookup(
        account: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        writableIndexes: [0, 1],
        readOnlyIndexes: [2]
    )

    let lookup2 = AddressTableLookup(
        account: "9aZyFqQ8tGKmXMvJhq2N6zY4CjQjU3FxNGEwsM9ynWqz",
        writableIndexes: [0],
        readOnlyIndexes: [1, 2, 3]
    )

    let message = V0Message(
        signatureCount: 1,
        readOnlyAccounts: 0,
        readOnlyNonSigners: 1,
        accounts: [
            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            "11111111111111111111111111111111",
        ],
        blockhash: "DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj",
        instructions: [],
        addressTableLookups: [lookup1, lookup2]
    )

    var buffer = SolanaTransactionBuffer()
    try message.solanaTransactionEncode(to: &buffer)

    let decoded = try V0Message(fromSolanaTransaction: &buffer)
    #expect(decoded == message)
    #expect(decoded.addressTableLookups.count == 2)
}

@Test func v0EmptyAddressTableLookups() throws {
    // V0 message with empty address table lookups array
    let message = V0Message(
        signatureCount: 1,
        readOnlyAccounts: 0,
        readOnlyNonSigners: 1,
        accounts: [
            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            "11111111111111111111111111111111",
        ],
        blockhash: "DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj",
        instructions: [],
        addressTableLookups: []
    )

    var buffer = SolanaTransactionBuffer()
    try message.solanaTransactionEncode(to: &buffer)

    let decoded = try V0Message(fromSolanaTransaction: &buffer)
    #expect(decoded == message)
    #expect(decoded.addressTableLookups.isEmpty)
}

// MARK: - Message Type Detection Tests

@Test func detectLegacyMessage() throws {
    let legacyTx = Transaction(
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

    let encoded = try legacyTx.encode()
    let decoded = try Transaction(bytes: encoded)

    // Verify it's decoded as legacy
    switch decoded.message {
    case .legacyMessage:
        break  // expected
    case .v0:
        Issue.record("Expected legacy message, got V0")
    }
}

@Test func detectV0Message() throws {
    let v0Tx = Transaction(
        signatures: [],
        message: .v0(
            V0Message(
                signatureCount: 1,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 1,
                accounts: [
                    "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                    "11111111111111111111111111111111",
                ],
                blockhash: "DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj",
                instructions: [],
                addressTableLookups: []
            )
        )
    )

    let encoded = try v0Tx.encode()
    let decoded = try Transaction(bytes: encoded)

    // Verify it's decoded as V0
    switch decoded.message {
    case .v0:
        break  // expected
    case .legacyMessage:
        Issue.record("Expected V0 message, got legacy")
    }
}

// MARK: - Message Field Tests

@Test func messageWithNoSigners() throws {
    // Edge case: transaction with no signers
    let message = LegacyMessage(
        signatureCount: 0,
        readOnlyAccounts: 0,
        readOnlyNonSigners: 2,
        accounts: [
            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            "11111111111111111111111111111111",
        ],
        blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
        instructions: []
    )

    var buffer = SolanaTransactionBuffer()
    try message.solanaTransactionEncode(to: &buffer)

    let decoded = try LegacyMessage(fromSolanaTransaction: &buffer)
    #expect(decoded.signatureCount == 0)
}

@Test func messageWithMaxAccounts() throws {
    // Test with many accounts (approaching limits)
    var accounts: [PublicKey] = []
    for i in 0..<64 {
        // Generate different public keys
        var bytes = [UInt8](repeating: UInt8(i), count: 32)
        bytes[0] = UInt8(i)
        accounts.append(PublicKey(bytes: bytes)!)
    }

    let message = LegacyMessage(
        signatureCount: 1,
        readOnlyAccounts: 0,
        readOnlyNonSigners: UInt8(accounts.count - 1),
        accounts: accounts,
        blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
        instructions: []
    )

    var buffer = SolanaTransactionBuffer()
    try message.solanaTransactionEncode(to: &buffer)

    let decoded = try LegacyMessage(fromSolanaTransaction: &buffer)
    #expect(decoded.accounts.count == 64)
}

@Test func messageAccountCounts() throws {
    // Test that account counts are properly tracked
    let message = LegacyMessage(
        signatureCount: 2,  // 2 signers total
        readOnlyAccounts: 1,  // 1 read-only signer
        readOnlyNonSigners: 2,  // 2 read-only non-signers
        accounts: [
            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",  // writable signer
            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",  // readonly signer
            "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",  // readonly non-signer
            "11111111111111111111111111111111",  // readonly non-signer
        ],
        blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
        instructions: []
    )

    var buffer = SolanaTransactionBuffer()
    try message.solanaTransactionEncode(to: &buffer)

    let decoded = try LegacyMessage(fromSolanaTransaction: &buffer)
    #expect(decoded.signatureCount == 2)
    #expect(decoded.readOnlyAccounts == 1)
    #expect(decoded.readOnlyNonSigners == 2)
}
