import ByteBuffer
import Foundation
import Testing

@testable import SolanaTransactions

@Test func shortInt() {
    var buffer = ByteBuffer(bytes: [0x03])
    #expect(decodeShortUInt16(buffer: &buffer) == 3)
}

@Test func shortInt2() {
    var buffer = ByteBuffer(bytes: [0x80, 0x01])
    #expect(decodeShortUInt16(buffer: &buffer)! == 128)
}

@Test func shortInt3() {
    var buffer = ByteBuffer()
    encodeShortUInt16(3, buffer: &buffer)
    #expect(buffer.readBytes(length: buffer.readableBytes) == [0x03])
}

@Test func shortInt4() {
    var buffer = ByteBuffer()
    encodeShortUInt16(128, buffer: &buffer)
    #expect(buffer.readBytes(length: buffer.readableBytes) == [0x80, 0x01])
}

@Test func shortInt5() {
    var buffer = ByteBuffer()
    for i in 0...UInt16.max {
        encodeShortUInt16(UInt16(i), buffer: &buffer)
    }
    for i in 0...UInt16.max {
        #expect(decodeShortUInt16(buffer: &buffer)! == i)
    }
}

@Test func getTransfer() async throws {
    let base64Transaction =
        "AVY2OiCW17TmRtYkLf5hXChKiLI426BCzVvm3HVWbfc9jB/bbeXBdr44qqHonxaXU72IujL8UxMHINFxdbiZrAaAAQABA406Qf3ITsphmePq8Dhvj5KuE1qYX1hOPOf02gP1OnSxqj7yZT8FPL8rBX8RYTg1teUdYh7ObB0gKMsyfCMWtzYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL7kT4hrkBAe9WQXo7ozykFkocGm47yXhDkJOG244K5sAQICAAEMAgAAAICWmAAAAAAAAA=="
    var transactionBytes = ByteBuffer(bytes: Data(base64Encoded: base64Transaction)!)

    let transaction = decodeTransaction(buffer: &transactionBytes)

    #expect(
        transaction.signatures == [
            [
                86, 54, 58, 32, 150, 215, 180, 230, 70, 214, 36,
                45, 254, 97, 92, 40, 74, 136, 178, 56, 219, 160,
                66, 205, 91, 230, 220, 117, 86, 109, 247, 61, 140,
                31, 219, 109, 229, 193, 118, 190, 56, 170, 161, 232,
                159, 22, 151, 83, 189, 136, 186, 50, 252, 83, 19,
                7, 32, 209, 113, 117, 184, 153, 172, 6,
            ]
        ])

    // Sender: {
    //   address: 'AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG',
    //   keyPair: [Object: null prototype] {
    //     privateKey: CryptoKey {
    //       type: 'private',
    //       extractable: false,
    //       algorithm: { name: 'Ed25519' },
    //       usages: [ 'sign' ]
    //     },
    //     publicKey: CryptoKey {
    //       type: 'public',
    //       extractable: true,
    //       algorithm: { name: 'Ed25519' },
    //       usages: [ 'verify' ]
    //     }
    //   },
    //   signMessages: [Function: signMessages],
    //   signTransactions: [Function: signTransactions]
    // }

    // Recipient: {
    //   address: 'CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu',
    //   keyPair: [Object: null prototype] {
    //     privateKey: CryptoKey {
    //       type: 'private',
    //       extractable: false,
    //       algorithm: { name: 'Ed25519' },
    //       usages: [ 'sign' ]
    //     },
    //     publicKey: CryptoKey {
    //       type: 'public',
    //       extractable: true,
    //       algorithm: { name: 'Ed25519' },
    //       usages: [ 'verify' ]
    //     }
    //   },
    //   signMessages: [Function: signMessages],
    //   signTransactions: [Function: signTransactions]
    // }

    // Transfer Lamports Amount: 10000000n

    // Signed Transaction: {
    //   lifetimeConstraint: {
    //     blockhash: 'DrAP91wtHVsYp64PYyhGLJXtbYMQt7Sss47YdKUV1Xzj',
    //     lastValidBlockHeight: 405980998n
    //   },
    //   messageBytes: Uint8Array(152) [
    //     128,   1,   0,   1,   3, 141,  58,  65, 253, 200,  78, 202,
    //      97, 153, 227, 234, 240,  56, 111, 143, 146, 174,  19,  90,
    //     152,  95,  88,  78,  60, 231, 244, 218,   3, 245,  58, 116,
    //     177, 170,  62, 242, 101,  63,   5,  60, 191,  43,   5, 127,
    //      17,  97,  56,  53, 181, 229,  29,  98,  30, 206, 108,  29,
    //      32,  40, 203,  50, 124,  35,  22, 183,  54,   0,   0,   0,
    //       0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    //       0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
    //       0,   0,   0,   0,   0, 190, 228,  79, 136, 107, 144,  16,
    //      30, 245, 100,  23, 163, 186,  51, 202,  65, 100, 161, 193,
    //     166, 227, 188, 151, 132,  57,   9,  56, 109, 184, 224, 174,
    //     108,   1,   2,   2,   0,   1,  12,   2,   0,   0,   0, 128,
    //     150, 152,   0,   0,   0,   0,   0,   0
    //   ],
    //   signatures: {
    //     AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG: Uint8Array(64) [
    //        86,  54,  58,  32, 150, 215, 180, 230,  70, 214,  36,
    //        45, 254,  97,  92,  40,  74, 136, 178,  56, 219, 160,
    //        66, 205,  91, 230, 220, 117,  86, 109, 247,  61, 140,
    //        31, 219, 109, 229, 193, 118, 190,  56, 170, 161, 232,
    //       159,  22, 151,  83, 189, 136, 186,  50, 252,  83,  19,
    //         7,  32, 209, 113, 117, 184, 153, 172,   6
    //     ]
    //   }
    // }

    // Serialized transaction: AVY2OiCW17TmRtYkLf5hXChKiLI426BCzVvm3HVWbfc9jB/bbeXBdr44qqHonxaXU72IujL8UxMHINFxdbiZrAaAAQABA406Qf3ITsphmePq8Dhvj5KuE1qYX1hOPOf02gP1OnSxqj7yZT8FPL8rBX8RYTg1teUdYh7ObB0gKMsyfCMWtzYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAL7kT4hrkBAe9WQXo7ozykFkocGm47yXhDkJOG244K5sAQICAAEMAgAAAICWmAAAAAAAAA==

}
