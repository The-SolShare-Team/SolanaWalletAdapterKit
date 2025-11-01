import Base58
import CryptoKit
import Foundation
import Salt
import SolanaRPC
import Testing

@testable import SolanaTransactions

@Test func encodeDecode() {
    let tr = try! Transaction(blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
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
                signatures: [],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 0,
                        accounts: [
                            "11111111111111111111111111111111",
                            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 0, accounts: [1, 2],
                                data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                            CompiledInstruction(
                                programIdIndex: 0, accounts: [1, 2],
                                data: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]),
                            CompiledInstruction(
                                programIdIndex: 0, accounts: [1, 2],
                                data: [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0]),
                            CompiledInstruction(
                                programIdIndex: 3, accounts: [1], data: [3, 0, 0, 0, 97, 98, 99]),
                        ]))))
}
