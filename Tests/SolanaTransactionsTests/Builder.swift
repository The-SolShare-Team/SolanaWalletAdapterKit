import CryptoKit
import Foundation
import Testing

@testable import SolanaTransactions

@Test func encodeDecode() {
    let tr = try! Transaction(
        feePayer: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
        blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk"
    ) {
        for i in 0..<3 {
            SystemProgram.transfer(
                from: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu", lamports: Int64(i))
        }
        if true {
            MemoProgram.publishMemo(
                account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG", memo: "abc")
        }
    }

    #expect(
        try! Transaction(bytes: try! tr.encode())
            == Transaction(
                signatures: ["1111111111111111111111111111111111111111111111111111111111111111"],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 2,
                        accounts: [
                            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "11111111111111111111111111111111",
                            "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 2, accounts: [0, 1],
                                data: [2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                            CompiledInstruction(
                                programIdIndex: 2, accounts: [0, 1],
                                data: [2, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]),
                            CompiledInstruction(
                                programIdIndex: 2, accounts: [0, 1],
                                data: [2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0]),
                            CompiledInstruction(
                                programIdIndex: 3, accounts: [0], data: [3, 0, 0, 0, 97, 98, 99]),
                        ]))))
}
