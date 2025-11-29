import Foundation
import Testing

@testable import SolanaTransactions

@Test func publicKey() throws {
    let data = try #require(Data(base58Encoded: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"))
    let publicKey = PublicKey(bytes: [UInt8](data))
    #expect(publicKey == "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG")
}

@Test func shortInt1() throws {
    var buffer = SolanaTransactionBuffer(bytes: [0x03])
    #expect(try UInt16(fromSolanaTransaction: &buffer) == 3)
}

@Test func shortInt2() throws {
    var buffer = SolanaTransactionBuffer(bytes: [0x80, 0x01])
    #expect(try UInt16(fromSolanaTransaction: &buffer) == 128)
}

@Test func shortInt3() throws {
    var buffer = SolanaTransactionBuffer()
    try UInt16(3).solanaTransactionEncode(to: &buffer)
    #expect(buffer.readBytes(length: buffer.readableBytes) == [0x03])
}

@Test func shortInt4() throws {
    var buffer = SolanaTransactionBuffer()
    try UInt16(128).solanaTransactionEncode(to: &buffer)
    #expect(buffer.readBytes(length: buffer.readableBytes) == [0x80, 0x01])
}

@Test func shortInt5() throws {
    var buffer = SolanaTransactionBuffer()

    for i in 0...UInt16.max {
        try UInt16(i).solanaTransactionEncode(to: &buffer)
    }

    for i in 0...UInt16.max {
        let value = try UInt16(fromSolanaTransaction: &buffer)
        #expect(value == i)
    }
}

@Test func array() throws {
    var buffer = SolanaTransactionBuffer()
    let original: [UInt8] = [1, 2, 3, 4, 5, 6]
    try original.solanaTransactionEncode(to: &buffer)
    #expect(try [UInt8].init(fromSolanaTransaction: &buffer) == original)
}

@Test func transaction() throws {
    let base64Transaction =
        """
        AVY2OiCW17TmRtYkLf5hXChKiLI426BCzVvm3HVWbfc9jB/bbeXBdr44qqHonxaXU72IujL8UxMHINFx\
        dbiZrAaAAQABA406Qf3ITsphmePq8Dhvj5KuE1qYX1hOPOf02gP1OnSxqj7yZT8FPL8rBX8RYTg1teUd\
        Yh7ObB0gKMsyfCMWtzYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL7kT4hrkBAe9WQXo7oz\
        ykFkocGm47yXhDkJOG244K5sAQICAAEMAgAAAICWmAAAAAAAAA==
        """

    let transaction = try Transaction(bytes: Data(base64Encoded: base64Transaction)!)

    let expected = Transaction(
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

    #expect(transaction == expected)
}

// lower level test for V0 transaction encoding/decoding
@Test func testV0TransactionEncodingMatchesJS() throws {
    let transaction = Transaction(
        signatures: [Signature.placeholder],
        message: .v0(
            V0Message(
                signatureCount: 1,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 1,
                accounts: [
                    PublicKey("Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"),
                    PublicKey("CxXjGnBqvcq73ZFP75SXoDVEZ5MhkNMPMRPQwpeUYFFk"),
                ],
                blockhash: "13uptgsxwDM8pzLj18FCqncEo8Nbz4srN3H7U6xqpaeq",
                instructions: [
                    CompiledInstruction(
                        programIdIndex: 0,
                        accounts: [1],
                        data: [0, 1]
                    )
                ],
                addressTableLookups: []
            ))
    )

    #expect(
        try transaction.encode().base64EncodedString() == """
            AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAACAAQABAgONOkH9yE7KYZnj6vA4b4+SrhNamF9YTjzn9NoD9Tp0sao+8mU/BTy/KwV/EWE4NbXl\
            HWIezmwdICjLMnwjFrcAvuRPiGuQEB71ZBejujPKQWShwabjvJeEOQk4bbjgrgEAAQECAAEA
            """)
}

@Test func testV0TransactionDecodingMatchesJS() throws {
    let base64TransactionFromJS = """
        AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
        AAAAAACAAQABAgONOkH9yE7KYZnj6vA4b4+SrhNamF9YTjzn9NoD9Tp0sao+8mU/BTy/KwV/EWE4NbXl\
        HWIezmwdICjLMnwjFrcAvuRPiGuQEB71ZBejujPKQWShwabjvJeEOQk4bbjgrgEAAQECAAEA
        """
    let transaction = try Transaction(bytes: Data(base64Encoded: base64TransactionFromJS)!)

    let expected = Transaction(
        signatures: [Signature.placeholder],
        message: .v0(
            V0Message(
                signatureCount: 1,
                readOnlyAccounts: 0,
                readOnlyNonSigners: 1,
                accounts: [
                    "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                    "CxXjGnBqvcq73ZFP75SXoDVEZ5MhkNMPMRPQwpeUYFFk",
                ],
                blockhash: "13uptgsxwDM8pzLj18FCqncEo8Nbz4srN3H7U6xqpaeq",
                instructions: [
                    CompiledInstruction(
                        programIdIndex: 0,
                        accounts: [1],
                        data: [0, 1]
                    )
                ],
                addressTableLookups: []
            ))
    )

    #expect(transaction == expected)
}
