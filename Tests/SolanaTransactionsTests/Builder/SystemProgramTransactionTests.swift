import CryptoKit
import Foundation
import Testing

@testable import SolanaTransactions

@Test func testSystemProgramCreateAccount() throws {
    let tx = try Transaction(feePayer: "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo", blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        SystemProgram.createAccount(
            from: "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
            newAccount: "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
            lamports: 1,
            space: 3,
            programId: SystemProgram.programId
        )
    }

    let decoded = try Transaction(bytes: try tx.encode())
    #expect(
        decoded
            == Transaction(
                signatures: [
                    "1111111111111111111111111111111111111111111111111111111111111111",
                    "1111111111111111111111111111111111111111111111111111111111111111",
                ],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 2, readOnlyAccounts: 0, readOnlyNonSigners: 1,
                        accounts: [
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
                            "11111111111111111111111111111111",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 2, accounts: [0, 1],
                                data: [
                                    0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
                                    0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0,
                                ])
                        ]))))
}
