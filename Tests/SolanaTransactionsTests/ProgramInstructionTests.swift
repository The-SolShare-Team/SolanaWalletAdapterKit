import Foundation
import Testing
import SwiftBorsh

@testable import SolanaTransactions

/// Tests for individual program instruction encoding
/// These tests verify that each program's instructions encode correctly
/// and match expected Solana instruction formats

// MARK: - System Program Tests

@Test func systemProgramTransfer() throws {
    let instruction = SystemProgram.transfer(
        from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
        lamports: 1_000_000
    )

    // Verify accounts
    #expect(instruction.accounts.count == 2)
    #expect(instruction.accounts[0].publicKey == "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG")
    #expect(instruction.accounts[0].isSigner == true)
    #expect(instruction.accounts[0].isWritable == true)
    #expect(instruction.accounts[1].publicKey == "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu")
    #expect(instruction.accounts[1].isSigner == false)
    #expect(instruction.accounts[1].isWritable == true)

    // Verify instruction data (index 0 for transfer, then lamports as i64)
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // Transfer instruction: [index: 4 bytes (0), lamports: 8 bytes]
    #expect(encoded.count == 12)
    #expect(encoded[0...3] == [0, 0, 0, 0])  // index = 0 (i32)
    #expect(encoded[4...11] == [64, 66, 15, 0, 0, 0, 0, 0])  // 1,000,000 in little-endian i64
}

@Test func systemProgramTransferZeroLamports() throws {
    let instruction = SystemProgram.transfer(
        from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
        lamports: 0
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    #expect(encoded.count == 12)
    #expect(encoded[0...3] == [0, 0, 0, 0])  // index = 0
    #expect(encoded[4...11] == [0, 0, 0, 0, 0, 0, 0, 0])  // 0 lamports
}

@Test func systemProgramTransferMaxLamports() throws {
    let maxLamports: Int64 = .max
    let instruction = SystemProgram.transfer(
        from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
        lamports: maxLamports
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    #expect(encoded.count == 12)
    #expect(encoded[0...3] == [0, 0, 0, 0])  // index = 0
    #expect(encoded[4...11] == [255, 255, 255, 255, 255, 255, 255, 127])  // max i64
}

@Test func systemProgramCreateAccount() throws {
    let instruction = SystemProgram.createAccount(
        from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        newAccount: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
        lamports: 1_000_000,
        space: 165,
        programId: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
    )

    // Verify accounts
    #expect(instruction.accounts.count == 2)
    #expect(instruction.accounts[0].isSigner == true)
    #expect(instruction.accounts[0].isWritable == true)
    #expect(instruction.accounts[1].isSigner == true)  // new account must sign
    #expect(instruction.accounts[1].isWritable == true)

    // Verify instruction data
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // CreateAccount: [index: 4 bytes (2), lamports: 8, space: 8, programId: 32]
    #expect(encoded.count == 52)
    #expect(encoded[0...3] == [2, 0, 0, 0])  // index = 2 (i32)
}

// MARK: - Token Program Tests

@Test func tokenProgramTransfer() throws {
    let instruction = TokenProgram.transfer(
        from: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        to: "9aZyFqQ8tGKmXMvJhq2N6zY4CjQjU3FxNGEwsM9ynWqz",
        amount: 1000,
        owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
    )

    // Verify accounts
    #expect(instruction.accounts.count == 3)
    #expect(instruction.accounts[0].isWritable == true)
    #expect(instruction.accounts[1].isWritable == true)
    #expect(instruction.accounts[2].isSigner == true)  // owner must sign

    // Verify instruction data
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // Transfer: [index: 1 byte (3), amount: 8 bytes]
    #expect(encoded.count == 9)
    #expect(encoded[0] == 3)  // index = 3 (u8)
    #expect(encoded[1...8] == [232, 3, 0, 0, 0, 0, 0, 0])  // 1000 in little-endian i64
}

@Test func tokenProgramTransferChecked() throws {
    let instruction = TokenProgram.transferChecked(
        from: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        to: "9aZyFqQ8tGKmXMvJhq2N6zY4CjQjU3FxNGEwsM9ynWqz",
        amount: 1000,
        decimals: 6,
        owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
    )

    // Verify accounts (includes mint)
    #expect(instruction.accounts.count == 4)
    #expect(instruction.accounts[2].isWritable == true)  // destination
    #expect(instruction.accounts[3].isSigner == true)  // owner must sign

    // Verify instruction data
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // TransferChecked: [index: 1 byte (12), amount: 8 bytes, decimals: 1 byte]
    #expect(encoded.count == 10)
    #expect(encoded[0] == 12)  // index = 12 (u8)
    #expect(encoded[1...8] == [232, 3, 0, 0, 0, 0, 0, 0])  // 1000 in little-endian i64
    #expect(encoded[9] == 6)  // decimals
}

@Test func tokenProgramInitializeMint() throws {
    let instruction = TokenProgram.initializeMint(
        mintAccount: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        decimals: 6,
        mintAuthority: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        freezeAuthority: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    )

    // Verify accounts
    #expect(instruction.accounts.count == 2)
    #expect(instruction.accounts[0].publicKey == "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v")
    #expect(instruction.accounts[0].isWritable == true)
    #expect(instruction.accounts[1].publicKey == TokenProgram.sysvarRentPubkey)

    // Verify instruction data
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // InitializeMint: [index: 1 byte (0), decimals: 1, mintAuth: 32, option: 1, freezeAuth: 32]
    #expect(encoded.count == 67)
    #expect(encoded[0] == 0)  // index
    #expect(encoded[1] == 6)  // decimals
}

@Test func tokenProgramInitializeMintNoFreezeAuthority() throws {
    let instruction = TokenProgram.initializeMint(
        mintAccount: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        decimals: 9,
        mintAuthority: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        freezeAuthority: nil
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // InitializeMint with no freeze authority: [index: 1, decimals: 1, mintAuth: 32, option: 1, zeros: 32]
    #expect(encoded.count == 67)
    #expect(encoded[0] == 0)  // index
    #expect(encoded[1] == 9)  // decimals
    #expect(encoded[34] == 0)  // option = 0 (None)
}

@Test func tokenProgramMintTo() throws {
    let instruction = TokenProgram.mintTo(
        mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        destination: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        mintAuthority: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        amount: 1_000_000
    )

    // Verify accounts
    #expect(instruction.accounts.count == 3)
    #expect(instruction.accounts[2].isSigner == true)  // mint authority must sign

    // Verify instruction data
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // MintTo: [index: 1 byte (7), amount: 8 bytes]
    #expect(encoded.count == 9)
    #expect(encoded[0] == 7)  // index = 7
    #expect(encoded[1...8] == [64, 66, 15, 0, 0, 0, 0, 0])  // 1,000,000
}

@Test func tokenProgramCloseAccount() throws {
    let instruction = TokenProgram.closeAccount(
        account: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        destination: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
    )

    // Verify accounts
    #expect(instruction.accounts.count == 3)
    #expect(instruction.accounts[2].isSigner == true)  // owner must sign

    // Verify instruction data
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // CloseAccount: [index: 1 byte (9)]
    #expect(encoded.count == 1)
    #expect(encoded[0] == 9)  // index = 9
}

@Test func tokenProgramInitializeAccount() throws {
    let instruction = TokenProgram.initializeAccount(
        account: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        owner: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
    )

    // Verify accounts
    #expect(instruction.accounts.count == 4)
    #expect(instruction.accounts[0].isWritable == true)  // account
    #expect(instruction.accounts[1].isWritable == false)  // mint (read-only)
    #expect(instruction.accounts[3].publicKey == TokenProgram.sysvarRentPubkey)

    // Verify instruction data
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // InitializeAccount: [index: 1 byte (1)]
    #expect(encoded.count == 1)
    #expect(encoded[0] == 1)  // index = 1
}

// MARK: - Memo Program Tests

@Test func memoProgramPublish() throws {
    let instruction = MemoProgram.publishMemo(
        account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        memo: "Hello Solana!"
    )

    // Verify accounts
    #expect(instruction.accounts.count == 1)
    #expect(instruction.accounts[0].publicKey == "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG")
    #expect(instruction.accounts[0].isSigner == true)

    // Verify instruction data (memo is length-prefixed string)
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    let expectedMemo = "Hello Solana!".utf8
    // [length: 4 bytes, string bytes]
    #expect(encoded.count == 4 + expectedMemo.count)
    #expect(encoded[0...3] == [13, 0, 0, 0])  // length = 13 (u32 little-endian)
    #expect(Array(encoded[4...]) == Array(expectedMemo))
}

@Test func memoProgramEmptyMemo() throws {
    let instruction = MemoProgram.publishMemo(
        account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        memo: ""
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    // Empty memo: [length: 4 bytes (0)]
    #expect(encoded.count == 4)
    #expect(encoded == [0, 0, 0, 0])
}

@Test func memoProgramLongMemo() throws {
    let longMemo = String(repeating: "A", count: 566)  // Solana memo max length
    let instruction = MemoProgram.publishMemo(
        account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        memo: longMemo
    )

    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    #expect(encoded.count == 4 + 566)
    #expect(encoded[0...3] == [54, 2, 0, 0])  // length = 566 (u32 little-endian)
}

// MARK: - Associated Token Program Tests

@Test func associatedTokenProgramCreate() throws {
    let instruction = AssociatedTokenProgram.createAssociatedTokenAccount(
        mint: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
        associatedAccount: "5n7VBS8hXLkjJzD1JRJndFV92jDpQ1PwZ4dvGQNqvCKp",
        owner: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
        payer: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"
    )

    // Verify accounts
    #expect(instruction.accounts.count == 7)
    #expect(instruction.accounts[0].isSigner == true)  // funder must sign
    #expect(instruction.accounts[0].isWritable == true)  // funder pays
    #expect(instruction.accounts[1].isWritable == true)  // associated account is created
    #expect(instruction.accounts[4].publicKey == SystemProgram.programId)
    #expect(instruction.accounts[5].publicKey == TokenProgram.programId)

    // Verify instruction data (no data for create)
    var buffer = BorshByteBuffer()
    try instruction.data.borshEncode(to: &buffer)
    let encoded = buffer.readBytes(length: buffer.readableBytes) ?? []

    #expect(encoded.isEmpty)
}

// MARK: - Program ID Tests

@Test func programIds() {
    #expect(SystemProgram.programId == "11111111111111111111111111111111")
    #expect(TokenProgram.programId == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA")
    #expect(MemoProgram.programId == "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr")
    #expect(AssociatedTokenProgram.programId == "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
}
