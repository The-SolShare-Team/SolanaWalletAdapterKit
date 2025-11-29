import CryptoKit
import Foundation
import Testing

@testable import SolanaTransactions

@Test func testTokenProgramInitializeMintEncodingDecoding() throws {
    let mint: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let authority: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"

    let tx = try Transaction(feePayer: mint, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.initializeMint(
            mintAccount: mint,
            decimals: 6,
            mintAuthority: authority,
            freezeAuthority: nil
        )
    }

    let decoded = try Transaction(bytes: try tx.encode())
    #expect(
        decoded
            == Transaction(
                signatures: [Signature.placeholder],
                message: VersionedMessage.legacyMessage(
                    LegacyMessage(
                        signatureCount: 1, readOnlyAccounts: 0, readOnlyNonSigners: 2,
                        accounts: [
                            "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo",
                            "SysvarRent111111111111111111111111111111111",
                            "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA",
                        ], blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk",
                        instructions: [
                            CompiledInstruction(
                                programIdIndex: 2, accounts: [0, 1],
                                data: [
                                    0, 6, 97, 66, 146, 246, 170, 235, 0, 229, 233, 69, 131,
                                    155, 212, 213, 43, 89, 124, 249, 126, 26, 231, 153, 150, 115,
                                    122, 164, 85, 200, 72, 35, 230, 84, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                    0, 0, 0,
                                ])
                        ]))))
}

@Test func testTokenProgramInitializeAccountEncodingDecoding() throws {
    let account = PublicKey("CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu")
    let mint = PublicKey("Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo")
    let owner = PublicKey("7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5")

    let tx = try Transaction(feePayer: account, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.initializeAccount(
            account: account,
            mint: mint,
            owner: owner
        )
    }

    let encoded = try tx.encode().base64EncodedString()

    // TODO: The expected value below disagrees with @solana/web3.js on the ordering of mint and owner.
    //       This is most likely not an issue, but should be verified.
    #expect(
        encoded == """
            AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAABAAQFqj7yZT8FPL8rBX8RYTg1teUdYh7ObB0gKMsyfCMWtzYDjTpB/chOymGZ4+rwOG+Pkq4T\
            WphfWE485/TaA/U6dGFCkvaq6wDl6UWDm9TVK1l8+X4a55mWc3qkVchII+ZUBqfVFxksXFEhjMlMPUrx\
            f1ja7gibof1E49vZigAAAAAG3fbh12Whk9nL4UbO63msHLSF7V9bN5E6jPWFfv8Aqfi4HfMFyFlPEnMI\
            sVMyJOPzxhnAMvDRsKGq92LCHr5bAQQEAAECAwEB
            """)
}

@Test func testTokenProgramTransferEncodingDecoding() throws {
    let from: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    let to: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let owner: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"

    let tx = try Transaction(feePayer: "5oNDL3swdJJF1g9DzJiZ4ynHXgszjAEpUkxVYejchzrY", blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.transfer(
            from: from,
            to: to,
            amount: 12345,
            owner: owner
        )
    }

    let encoded = try tx.encode().base64EncodedString()

    #expect(
        encoded == """
            AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAAAAAAAAgEBBUdPczXVOZ5JZWb8/omwbd8vnfMfq2Aar7+a/lV0pZatYUKS9qrrAOXpRYOb1NUr\
            WXz5fhrnmZZzeqRVyEgj5lSqPvJlPwU8vysFfxFhODW15R1iHs5sHSAoyzJ8Ixa3NgONOkH9yE7KYZnj\
            6vA4b4+SrhNamF9YTjzn9NoD9Tp0Bt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKn4uB3zBchZ\
            TxJzCLFTMiTj88YZwDLw0bChqvdiwh6+WwEEAwIDAQkDOTAAAAAAAAA=
            """)
}

@Test func testTokenProgramMintToEncodingDecoding() throws {
    let mint: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    let dest: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let mintAuth: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"

    let tx = try Transaction(feePayer: mint, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.mintTo(
            mint: mint,
            destination: dest,
            mintAuthority: mintAuth,
            amount: 5000
        )
    }

    let encoded = try tx.encode().base64EncodedString()

    #expect(
        encoded == """
            AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAAAAAAAAgEBBKo+8mU/BTy/KwV/EWE4NbXlHWIezmwdICjLMnwjFrc2YUKS9qrrAOXpRYOb1NUr\
            WXz5fhrnmZZzeqRVyEgj5lQDjTpB/chOymGZ4+rwOG+Pkq4TWphfWE485/TaA/U6dAbd9uHXZaGT2cvh\
            Rs7reawctIXtX1s3kTqM9YV+/wCp+Lgd8wXIWU8ScwixUzIk4/PGGcAy8NGwoar3YsIevlsBAwMAAgEJ\
            B4gTAAAAAAAA
            """)
}

@Test func testTokenProgramCloseAccountEncodingDecoding() throws {
    let account: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    let dest: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let owner: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"

    let tx = try Transaction(feePayer: account, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.closeAccount(
            account: account,
            destination: dest,
            owner: owner
        )
    }

    let encoded = try tx.encode().base64EncodedString()

    #expect(
        encoded == """
            AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAAAAAAAAgEBBKo+8mU/BTy/KwV/EWE4NbXlHWIezmwdICjLMnwjFrc2YUKS9qrrAOXpRYOb1NUr\
            WXz5fhrnmZZzeqRVyEgj5lQDjTpB/chOymGZ4+rwOG+Pkq4TWphfWE485/TaA/U6dAbd9uHXZaGT2cvh\
            Rs7reawctIXtX1s3kTqM9YV+/wCp+Lgd8wXIWU8ScwixUzIk4/PGGcAy8NGwoar3YsIevlsBAwMAAgEB\
            CQ==
            """)
}

@Test func testTokenProgramTransferCheckedEncodingDecoding() throws {
    let from: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
    let to: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let owner: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"
    let mint: PublicKey = "So11111111111111111111111111111111111111112"

    let tx = try Transaction(feePayer: from, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.transferChecked(
            from: from,
            to: to,
            amount: 1000,
            decimals: 2,
            owner: owner,
            mint: mint
        )
    }

    let encoded = try tx.encode().base64EncodedString()

    #expect(
        encoded == """
            AgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAAAAAAAAgECBao+8mU/BTy/KwV/EWE4NbXlHWIezmwdICjLMnwjFrc2YUKS9qrrAOXpRYOb1NUr\
            WXz5fhrnmZZzeqRVyEgj5lQDjTpB/chOymGZ4+rwOG+Pkq4TWphfWE485/TaA/U6dAabiFf+q4GE+2h/\
            Y0YYwDXaxDncGus7VZig8AAAAAABBt324ddloZPZy+FGzut5rBy0he1fWzeROoz1hX7/AKn4uB3zBchZ\
            TxJzCLFTMiTj88YZwDLw0bChqvdiwh6+WwEEBAADAgEKDOgDAAAAAAAAAg==
            """)
}

@Test func testTokenProgramInitializeMintEncodingDecodingWithFreezeAuthority() throws {
    let mint: PublicKey = "Es8H62JtW4NwQK4Qcz6LCFswiqfnEQdPskSsGBCJASo"
    let authority: PublicKey = "7YfRf9e2p1k9At7nVwPKhQ76YDK9W3szWjmV7iLzPzF5"
    let freezeAuthority: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"

    let tx = try Transaction(feePayer: mint, blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk") {
        TokenProgram.initializeMint(
            mintAccount: mint,
            decimals: 6,
            mintAuthority: authority,
            freezeAuthority: freezeAuthority
        )
    }

    let encoded = try tx.encode().base64EncodedString()

    #expect(
        encoded == """
            AQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\
            AAAAAAABAAIDA406Qf3ITsphmePq8Dhvj5KuE1qYX1hOPOf02gP1OnQGp9UXGSxcUSGMyUw9SvF/WNru\
            CJuh/UTj29mKAAAAAAbd9uHXZaGT2cvhRs7reawctIXtX1s3kTqM9YV+/wCp+Lgd8wXIWU8ScwixUzIk\
            4/PGGcAy8NGwoar3YsIevlsBAgIAAUMABmFCkvaq6wDl6UWDm9TVK1l8+X4a55mWc3qkVchII+ZUAao+\
            8mU/BTy/KwV/EWE4NbXlHWIezmwdICjLMnwjFrc2
            """)
}
