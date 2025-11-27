import Base58
import CryptoKit
import Foundation
import Salt
import SolanaRPC
import Testing

@testable import SolanaTransactions

@Test func testTokenProgramInitializeMintEncodingDecoding() {
    let mint: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let authority: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"

    let tx = try! Transaction(feePayer: mint, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {        
        TokenProgram.initializeMint(
            mintAccount: mint,
            decimals: 6,
            mintAuthority: authority,
            freezeAuthority: nil
        )
    }

    //errors w following test: 
    //do we assume that the mint and the feePayer are from the same account? in web3.js we have the option to specify a different feePayer
    //signatureAccount and readOnylNonSigners differ from actual, should be signatureCount: 1, readOnlyNonSigners: 2
    let decoded = try! Transaction(bytes: try! tx.encode())
    #expect(decoded == Transaction(
                signatures: ["1111111111111111111111111111111111111111111111111111111111111111"],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 2,
                        accounts: [
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "SysvarRent111111111111111111111111111111111",
                            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
                          ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 2, accounts: [0,1],
                                data: [0, 6, 97, 66, 146, 246, 170, 235, 0, 229, 233, 69, 131, 
                                155, 212, 213, 43, 89, 124, 249, 126, 26, 231, 153, 150, 115, 
                                122, 164, 85, 200, 72, 35, 230, 84, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
                                0, 0, 0]),
                        ]))))
}

//problems with test: need to flip both the mint account and account meta
//signatureCount and readOnlyNonSigners differ from actual, should be signatureCount: 1, readOnlyNonSigners: 3 BIG ONE 
//accounts indexes are wrong, a little worried about that one
@Test func testTokenProgramInitializeAccountEncodingDecoding() {
    let account = PublicKey("CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu")
    let mint = PublicKey("Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo")
    let owner = PublicKey("7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5")

    let tx = try! Transaction(feePayer: account, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.initializeAccount(
            account: account,
            mint: mint,
            owner: owner
        )
    }

    let decoded = try! Transaction(bytes: try! tx.encode())

    let expectedTransaction = Transaction(
        signatures: ["1111111111111111111111111111111111111111111111111111111111111111"],
        message: VersionedMessage.legacyMessage(
            LegacyMessage(
                signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 3,
                accounts: [
                    "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                    "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                    "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
                    "SysvarRent111111111111111111111111111111111",
                    "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
                ],
                blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                instructions: [
                    CompiledInstruction(
                        programIdIndex: 4,
                        accounts: [0, 1, 2, 3],
                        data: [2]
                    )
                ]
            )
        )
    )

    #expect(decoded == expectedTransaction)
}

//Error here:  once again signatureCount and readOnlyNonSigners differ from actual, should be signatureCount: 1, readOnlyNonSigners: 3
@Test func testTokenProgramTransferEncodingDecoding() {
    let from: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    let to: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let owner: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"

    let tx = try! Transaction(feePayer: from, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.transfer(
            from: from,
            to: to,
            amount: 12345,
            owner: owner
        )
    }

    let decoded = try! Transaction(bytes: try! tx.encode())
    #expect(decoded == Transaction(
                signatures: ["1111111111111111111111111111111111111111111111111111111111111111", "1111111111111111111111111111111111111111111111111111111111111111"],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 2, readOnlyAccounts: 0, readOnlyNonSigners: 1,
                        accounts: [
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
                            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 3, accounts: [0, 1, 2],
                                data: [3,57,48,0,0,0,0,0,0]),
                        ]))))

}

//Error here:  once again signatureCount and readOnlyNonSigners differ from actual, should be signatureCount: 1, readOnlyNonSigners: 3
@Test func testTokenProgramMintToEncodingDecoding() {
    let mint: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    let dest: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let mintAuth: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"

    let tx = try! Transaction(feePayer: mint, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.mintTo(
            mint: mint,
            destination: dest,
            mintAuthority: mintAuth,
            amount: 5000
        )
    }

    let decoded = try! Transaction(bytes: try! tx.encode())

    #expect(decoded == Transaction(
                signatures: ["1111111111111111111111111111111111111111111111111111111111111111", "1111111111111111111111111111111111111111111111111111111111111111"],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 2, readOnlyAccounts: 0, readOnlyNonSigners: 1,
                        accounts: [
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
                            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 3, accounts: [0, 1, 2],
                                data: [7,136,19,0,0,0,0,0,0]),
                        ]))))
}

//error: once again signatureCount and readOnlyNonSigners differ from actual, should be signatureCount: 2, readOnlyAccounts: 1, readOnlyNonSigners: 1,

@Test func testTokenProgramCloseAccountEncodingDecoding() {
    let account: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    let dest: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let owner: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"

    let tx = try! Transaction(feePayer: account, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.closeAccount(
            account: account,
            destination: dest,
            owner: owner
        )
    }

    let decoded = try! Transaction(bytes: try! tx.encode())

    #expect(decoded == Transaction(
                signatures: ["1111111111111111111111111111111111111111111111111111111111111111", "1111111111111111111111111111111111111111111111111111111111111111"],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 2, readOnlyAccounts: 0, readOnlyNonSigners: 1,
                        accounts: [
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
                            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 3, accounts: [0, 1, 2],
                                data: [9]),
                        ]))))
}

//error once again signatureCount: 2, readOnlyAccounts: 1, readOnlyNonSigners: 2,
@Test func testTokenProgramTransferCheckedEncodingDecoding() {
    let from: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    let to: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let owner: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"
    let mint: PublicKey = "So11111111111111111111111111111111111111112"

    let tx = try! Transaction(feePayer: from, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.transferChecked(
            from: from,
            to: to,
            amount: 1000,
            decimals: 2,
            owner: owner,
            mint: mint
        )
    }

    let decoded = try! Transaction(bytes: try! tx.encode())

    #expect(decoded == Transaction(
                signatures: ["1111111111111111111111111111111111111111111111111111111111111111", "1111111111111111111111111111111111111111111111111111111111111111"],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 2, readOnlyAccounts: 0, readOnlyNonSigners: 2,
                        accounts: [
                            "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
                            "So11111111111111111111111111111111111111112",
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5",
                            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 4, accounts: [0, 1, 2, 3],
                                data: [12, 232, 3, 0, 0, 0, 0, 0, 0, 2]),
                        ]))))
}

@Test func testTokenProgramInitializeMintEncodingDecodingWithFreezeAuthority() {
    let mint: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let authority: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"
    let freezeAuthority: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"

    let tx = try! Transaction(feePayer: mint, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {        
        TokenProgram.initializeMint(
            mintAccount: mint,
            decimals: 6,
            mintAuthority: authority,
            freezeAuthority: freezeAuthority
        )
    }

    //errors w following test: 
    //do we assume that the mint and the feePayer are from the same account? in web3.js we have the option to specify a different feePayer
    //signatureAccount and readOnylNonSigners differ from actual, should be signatureCount: 1, readOnlyNonSigners: 2
    let decoded = try! Transaction(bytes: try! tx.encode())
    #expect(decoded == Transaction(
                signatures: ["1111111111111111111111111111111111111111111111111111111111111111"],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 2,
                        accounts: [
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "SysvarRent111111111111111111111111111111111",
                            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
                          ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 2, accounts: [0,1],
                                data: [0,6,97,66,146,246,170,235,0,229,233,69,131,155,212,213,
                                43,89,124,249,126,26,231,153,150,115,122,164,85,200,72,35,230,
                                84,1,170,62,242,101,63,5,60,191,43,5,127,17,97,56,53,181,229,
                                29,98,30,206,108,29,32,40,203,50,124,35,22,183,54]),
                        ]))))
}





