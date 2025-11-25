import Foundation
import Testing

@testable import SolanaTransactions

@Test func shortInt1() {
    var buffer = SolanaTransactionBuffer(bytes: [0x03])
    #expect(try! UInt16(fromSolanaTransaction: &buffer) == 3)
}

@Test func shortInt2() {
    var buffer = SolanaTransactionBuffer(bytes: [0x80, 0x01])
    #expect(try! UInt16(fromSolanaTransaction: &buffer) == 128)
}

@Test func shortInt3() {
    var buffer = SolanaTransactionBuffer()
    try! UInt16(3).solanaTransactionEncode(to: &buffer)
    #expect(buffer.readBytes(length: buffer.readableBytes) == [0x03])
}

@Test func shortInt4() {
    var buffer = SolanaTransactionBuffer()
    try! UInt16(128).solanaTransactionEncode(to: &buffer)
    #expect(buffer.readBytes(length: buffer.readableBytes) == [0x80, 0x01])
}

@Test func shortInt5() {
    var buffer = SolanaTransactionBuffer()
    for i in 0...UInt16.max {
        try! UInt16(i).solanaTransactionEncode(to: &buffer)
    }
    for i in 0...UInt16.max {
        #expect(try! UInt16(fromSolanaTransaction: &buffer) == i)
    }
}

@Test func array() {
    var buffer = SolanaTransactionBuffer()
    let original: [UInt8] = [1, 2, 3, 4, 5, 6]
    try! original.solanaTransactionEncode(to: &buffer)
    #expect(try! [UInt8].init(fromSolanaTransaction: &buffer) == original)
}

@Test func transaction() {
    let base64Transaction =
        "AVY2OiCW17TmRtYkLf5hXChKiLI426BCzVvm3HVWbfc9jB/bbeXBdr44qqHonxaXU72IujL8UxMHINFxdbiZrAaAAQABA406Qf3ITsphmePq8Dhvj5KuE1qYX1hOPOf02gP1OnSxqj7yZT8FPL8rBX8RYTg1teUdYh7ObB0gKMsyfCMWtzYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL7kT4hrkBAe9WQXo7ozykFkocGm47yXhDkJOG244K5sAQICAAEMAgAAAICWmAAAAAAAAA=="

    let transaction = try! Transaction(bytes: Data(base64Encoded: base64Transaction)!)

    #expect(
        transaction
            == Transaction(
                signatures: [
                    "2iyMu2haKjkw8bAHgpkSaKHSiVawRdCtEn4rCgfGQmztJ51AGX8iB99R41VyYVGjNK8TCRDRr6zVx7jznL5zr4ah"
                ],
                message: .v0(
                    V0Message(
                        signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 1,
                        accounts: [
                            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "11111111111111111111111111111111",
                        ], blockhash: "DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj",
                        instructions: [
                        CompiledInstruction(  // Transfer Lamports Amount: 10000000n
                                programIdIndex: 2, accounts: [0, 1],
                                data: [2, 0, 0, 0, 128, 150, 152, 0, 0, 0, 0, 0])
                        ],
                        addressTableLookups: [])))
    )
}

// lower level test for V0 transaction encoding/decoding
@Test func testV0TransactionEncodingMatchesJS() throws {
    // === Accounts ===
    let accounts: [PublicKey] = [
        PublicKey("Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"),
        PublicKey("CxXjGnBqvcq73ZFP75SXoDVEZ5MhkNMPMRPQwpeUYFFk"),
    ]
    
    // === Blockhash ===
    let blockhash = Blockhash("13uptgsxwDM8pzLj18FCqncEo8Nbz4srN3H7U6xqpaeq")
    
    // === Compiled Instruction ===
    let instruction = CompiledInstruction(
        programIdIndex: 0,
        accounts: [1],
        data: [0, 1]
    )
    
    // === Construct V0Message ===
    let message: V0Message = V0Message(
        signatureCount: 1,
        readOnlyAccounts: 0,
        readOnlyNonSigners: 1,
        accounts: accounts,
        blockhash: blockhash,
        instructions: [instruction],
        addressTableLookups: []
    )
    
    let placeholderSignature = Signature(bytes: Data(repeating: UInt8(0), count: 64))
    let signatures: [Signature] = [placeholderSignature]
    
    let transaction = Transaction(
        signatures: signatures,
        message: .v0(message)
    )
    
    let bytes = try transaction.encode()
    let encodedString = Data(bytes).base64EncodedString()
    
    #expect(encodedString == "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAQABAgONOkH9yE7KYZnj6vA4b4+SrhNamF9YTjzn9NoD9Tp0sao+8mU/BTy/KwV/EWE4NbXlHWIezmwdICjLMnwjFrcAvuRPiGuQEB71ZBejujPKQWShwabjvJeEOQk4bbjgrgEAAQECAAEA")
}

//use lower version transaction from JS to test decoding
@Test func testV0TransactionDecodingMatchesJS() throws {
    let base64TransactionFromJS =
        "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAQABAgONOkH9yE7KYZnj6vA4b4+SrhNamF9YTjzn9NoD9Tp0sao+8mU/BTy/KwV/EWE4NbXlHWIezmwdICjLMnwjFrcAvuRPiGuQEB71ZBejujPKQWShwabjvJeEOQk4bbjgrgEAAQECAAEA"
    let transaction = try Transaction(bytes: Data(base64Encoded: base64TransactionFromJS)!)
    let expectedAccounts: [PublicKey] = [
        PublicKey("Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"),
        PublicKey("CxXjGnBqvcq73ZFP75SXoDVEZ5MhkNMPMRPQwpeUYFFk"),
    ]
    let expectedBlockhash = Blockhash("13uptgsxwDM8pzLj18FCqncEo8Nbz4srN3H7U6xqpaeq")
    let expectedInstruction = CompiledInstruction(
        programIdIndex: 0,
        accounts: [1],
        data: [0, 1]
    )
    let expectedMessage = V0Message(
        signatureCount: 1,
        readOnlyAccounts: 0,
        readOnlyNonSigners: 1,
        accounts: expectedAccounts,
        blockhash: expectedBlockhash,
        instructions: [expectedInstruction],
        addressTableLookups: []
    )
    let expectedSignature = Signature(bytes: Data(repeating: UInt8(0), count: 64))
    #expect(
        transaction
            == Transaction(
                signatures: [expectedSignature],
                message: .v0(expectedMessage)
            )
    )
}

@Test func testV0TransactionEncodingHigherLevel() {
    let transaction: Transaction = try! Transaction(blockhash: "13uptgsxwDM8pzLj18FCqncEo8Nbz4srN3H7U6xqpaeq") {
        SystemProgram.transfer(
            from: "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
            to: "CxXjGnBqvcq73ZFP75SXoDVEZ5MhkNMPMRPQwpeUYFFk", lamports: 256)
    }
    
    let bytes = try! transaction.encode()
    let encodedString = Data(bytes).base64EncodedString()
    
    print(encodedString)
    #expect(encodedString == "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAEDA406Qf3ITsphmePq8Dhvj5KuE1qYX1hOPOf02gP1OnSxqj7yZT8FPL8rBX8RYTg1teUdYh7ObB0gKMsyfCMWtwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL7kT4hrkBAe9WQXo7ozykFkocGm47yXhDkJOG244K4BAgIAAQwCAAAAAAEAAAAAAAA=")
}

@Test func testV0TransactionDecodingHigherLevel() {
    let base64TransactionFromJS =
        "AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAEDA406Qf3ITsphmePq8Dhvj5KuE1qYX1hOPOf02gP1OnSxqj7yZT8FPL8rBX8RYTg1teUdYh7ObB0gKMsyfCMWtwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL7kT4hrkBAe9WQXo7ozykFkocGm47yXhDkJOG244K4BAgIAAQwCAAAAAAEAAAAAAAA="
    let transaction = try! Transaction(bytes: Data(base64Encoded: base64TransactionFromJS)!)
    let expectedTransaction: Transaction = try! Transaction(blockhash: "13uptgsxwDM8pzLj18FCqncEo8Nbz4srN3H7U6xqpaeq") {
        SystemProgram.transfer(
            from: "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
            to: "CxXjGnBqvcq73ZFP75SXoDVEZ5MhkNMPMRPQwpeUYFFk", lamports: 256)
    }
    print(transaction)
    print(expectedTransaction)
    #expect(transaction == expectedTransaction)
}
