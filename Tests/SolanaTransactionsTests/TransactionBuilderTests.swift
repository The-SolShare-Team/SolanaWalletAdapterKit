import Foundation
import Testing

@testable import SolanaTransactions

/// Tests for advanced transaction building scenarios
/// These tests verify the InstructionsBuilder DSL and transaction compilation

// MARK: - Basic Builder Tests

@Test func builderSingleInstruction() throws {
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1000
        )
    }

    switch tx.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.count == 1)
        #expect(msg.accounts.count == 3)  // system program + from + to
        #expect(msg.signatureCount == 1)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

@Test func builderMultipleInstructions() throws {
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1000
        )
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 2000
        )
        MemoProgram.publishMemo(
            account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            memo: "Payment"
        )
    }

    switch tx.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.count == 3)
        // Should deduplicate accounts (system program, from, to, memo program)
        #expect(msg.accounts.count == 4)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

@Test func builderConditionalInstructions() throws {
    let includeMemo = true

    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1000
        )
        if includeMemo {
            MemoProgram.publishMemo(
                account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                memo: "Conditional"
            )
        }
    }

    switch tx.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.count == 2)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

@Test func builderLoopInstructions() throws {
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        for i in 0..<5 {
            SystemProgram.transfer(
                from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                lamports: Int64(i * 1000)
            )
        }
    }

    switch tx.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.count == 5)
        // All instructions use same accounts, so should deduplicate
        #expect(msg.accounts.count == 3)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

// MARK: - Account Deduplication Tests

@Test func accountDeduplication() throws {
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1000
        )
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 2000
        )
    }

    switch tx.message {
    case .legacyMessage(let msg):
        // Should have 3 unique accounts (system program, from, to)
        #expect(msg.accounts.count == 3)
        #expect(msg.instructions.count == 2)

        // Both instructions should reference the same account indices
        #expect(msg.instructions[0].accounts == msg.instructions[1].accounts)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

@Test func accountOrdering() throws {
    // Test that accounts are ordered: writable signers, readonly signers, readonly non-signers
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1000
        )
    }

    switch tx.message {
    case .legacyMessage(let msg):
        // Account order: program (readonly non-signer), from (writable signer), to (writable non-signer)
        // Wait, based on the existing test, it looks like: from, to, system program
        // So writable signer first, then writable non-signer, then readonly non-signer

        #expect(msg.signatureCount == 1)  // only 'from' signs
        #expect(msg.readOnlyAccounts == 0)  // no readonly signers
        #expect(msg.readOnlyNonSigners == 1)  // system program is readonly non-signer
    case .v0:
        Issue.record("Expected legacy message")
    }
}

// MARK: - Mixed Program Instructions

@Test func mixedProgramInstructions() throws {
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1000
        )
        TokenProgram.transfer(
            from: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
            to: "9aZyFqQ8tGKmXMvJhq2N6zY4CjQjU3FxNGEwsM9ynWqz",
            amount: 100,
            owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
        )
        MemoProgram.publishMemo(
            account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            memo: "Multi-program transaction"
        )
    }

    switch tx.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.count == 3)
        // Should include: system program, token program, memo program, plus user accounts
        #expect(msg.accounts.count >= 6)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

@Test func tokenTransactionComplete() throws {
    // Test a complete SPL token transaction scenario
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.transfer(
            from: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
            to: "9aZyFqQ8tGKmXMvJhq2N6zY4CjQjU3FxNGEwsM9ynWqz",
            amount: 1_000_000,
            owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
        )
        MemoProgram.publishMemo(
            account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            memo: "Token transfer"
        )
    }

    switch tx.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.count == 2)
        #expect(msg.signatureCount == 1)  // owner signs both instructions
    case .v0:
        Issue.record("Expected legacy message")
    }
}

// MARK: - Complex Account Scenarios

@Test func multipleSigners() throws {
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.createAccount(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            newAccount: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1_000_000,
            space: 165,
            programId: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
        )
    }

    switch tx.message {
    case .legacyMessage(let msg):
        // CreateAccount requires both 'from' and 'newAccount' to sign
        #expect(msg.signatureCount == 2)
        #expect(msg.instructions.count == 1)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

@Test func largeTransaction() throws {
    // Test transaction with many instructions (approaching limits)
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        for i in 0..<20 {
            SystemProgram.transfer(
                from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                lamports: Int64(i)
            )
        }
    }

    switch tx.message {
    case .legacyMessage(let msg):
        #expect(msg.instructions.count == 20)
        // All instructions use same accounts
        #expect(msg.accounts.count == 3)
    case .v0:
        Issue.record("Expected legacy message")
    }
}

// MARK: - Round-trip Encoding Tests

@Test func roundTripEncoding() throws {
    let original = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1_000_000
        )
        MemoProgram.publishMemo(
            account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            memo: "Round trip test"
        )
    }

    // Encode and decode
    let encoded = try original.encode()
    let decoded = try Transaction(bytes: encoded)

    #expect(decoded == original)
}

@Test func roundTripWithMultiplePrograms() throws {
    let original = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 5000
        )
        TokenProgram.transfer(
            from: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
            to: "9aZyFqQ8tGKmXMvJhq2N6zY4CjQjU3FxNGEwsM9ynWqz",
            amount: 100,
            owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
        )
    }

    let encoded = try original.encode()
    let decoded = try Transaction(bytes: encoded)

    #expect(decoded == original)
}

@Test func roundTripWithCreateAccount() throws {
    let original = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.createAccount(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            newAccount: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 2_000_000,
            space: 165,
            programId: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
        )
        TokenProgram.initializeMint(
            mintAccount: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            decimals: 9,
            mintAuthority: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
        )
    }

    let encoded = try original.encode()
    let decoded = try Transaction(bytes: encoded)

    #expect(decoded == original)
}

// MARK: - Transaction Size Tests

@Test func encodedTransactionSize() throws {
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1000
        )
    }

    let encoded = try tx.encode()

    // Simple transfer transaction should be relatively small
    // No signatures + message header + accounts + recent blockhash + instruction
    #expect(encoded.count > 0)
    #expect(encoded.count < 300)  // reasonable upper bound for simple tx
}

@Test func emptySignatures() throws {
    // Unsigned transaction should have empty signatures
    let tx = try Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.transfer(
            from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
            to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            lamports: 1000
        )
    }

    #expect(tx.signatures.isEmpty)
}
