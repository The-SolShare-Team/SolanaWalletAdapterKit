import Base58
import CryptoKit
import Foundation
import Salt
import SolanaRPC
import Testing

@testable import SolanaTransactions

@Test func encode() async {
    let client = SolanaRPCClient(endpoint: .mainnetBeta)

    let tr = try! Transaction(blockhash: try! await client.getLatestBlockhash().blockhash) {
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

    print(Base58.encode(try! tr.encode()))
}

@Test func decode() async {
    let base58Transaction =
        "1ENxZs5qjpvNpru5C945cHuwBQyDoLfZmEjpdSE9RXBg7GyPEX25DsAD1XRfjffBucYxHm2Kn8KxFTWTacpTVWgmUwTwKR6ezuuoBxnXghB2UrPJ2Jc1L3esGDtv35JEe2cwFQbDUYc9F9qphNDQu83L2KX38iPgwxRig9nia36DQ5XhkoUpsGWbX1TaykivPQXngVaSud86pgPaxnVBt6rH8xU4cSYi3HmNzFVUo3cVkdfn7Qv9qdZVtWPzyMjzcH8gSAVDzmb6tJu1wtht3eVJvfNhEZaxSRqEjYy9gLixb3y9jTeuZk"

    let transaction = try! Transaction(bytes: try! Base58.decode(base58Transaction))

    #expect(
        transaction
            == Transaction(
                signatures: [],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 0,
                        accounts: [
                            "11111111111111111111111111111111",
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG",
                            "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            SolanaTransactions.CompiledInstruction(
                                programIdIndex: 0, accounts: [2, 1],
                                data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
                            SolanaTransactions.CompiledInstruction(
                                programIdIndex: 0, accounts: [2, 1],
                                data: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]),
                            SolanaTransactions.CompiledInstruction(
                                programIdIndex: 0, accounts: [2, 1],
                                data: [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0]),
                            SolanaTransactions.CompiledInstruction(
                                programIdIndex: 3, accounts: [2], data: [3, 0, 0, 0, 97, 98, 99]),
                        ]))))
}
