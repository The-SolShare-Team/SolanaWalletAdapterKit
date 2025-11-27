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
        #expect(try UInt16(fromSolanaTransaction: &buffer) == i)
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

    #expect(
        transaction
            == Transaction(
                signatures: [
                    [
                        86, 54, 58, 32, 150, 215, 180, 230, 70, 214, 36,
                        45, 254, 97, 92, 40, 74, 136, 178, 56, 219, 160,
                        66, 205, 91, 230, 220, 117, 86, 109, 247, 61, 140,
                        31, 219, 109, 229, 193, 118, 190, 56, 170, 161, 232,
                        159, 22, 151, 83, 189, 136, 186, 50, 252, 83, 19,
                        7, 32, 209, 113, 117, 184, 153, 172, 6,
                    ]
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
