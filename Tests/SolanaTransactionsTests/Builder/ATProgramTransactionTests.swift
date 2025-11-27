import CryptoKit
import Foundation
import Testing

@testable import SolanaTransactions

@Test func testAssociatedTokenProgramCreateAccount() throws {
    let tx = try Transaction(feePayer: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG", blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {        
        AssociatedTokenProgram.createAssociatedTokenAccount(
            mint: "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
            associatedAccount: "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
            owner: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
            payer: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        )
    }

    //read only signers error again
    let decoded = try Transaction(bytes: try tx.encode())
    #expect(decoded == Transaction(
                signatures: ["1111111111111111111111111111111111111111111111111111111111111111"],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 6, //should be 1, 0, 5
                        accounts: [
                            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                            "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "11111111111111111111111111111111",
                            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                            "SysvarRent111111111111111111111111111111111",
                            "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL",
                          ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 7, accounts: [0, 1, 2, 3, 4, 5, 6],
                                data: []),
                        ]))))
}
