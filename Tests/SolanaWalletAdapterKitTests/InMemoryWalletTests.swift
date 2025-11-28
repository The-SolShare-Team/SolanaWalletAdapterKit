import CryptoKit
import Foundation
import SolanaTransactions
import Testing

@testable import SolanaWalletAdapterKit

@Suite class InMemoryWalletTests {
    let wallet: InMemoryWallet

    init() async throws {
        wallet = InMemoryWallet(
            for: AppIdentity(name: "TestApp", url: URL(string: "https://example.com")!, icon: "favicon.ico"), cluster: .testnet)
        try wallet.connect()
    }

    @Test func connectDisconnect() async throws {
        let firstPublicKey = try #require(wallet.publicKey)

        try wallet.disconnect()
        #expect(!wallet.isConnected)

        try wallet.connect()
        #expect(wallet.isConnected)
        let secondPublicKey = try #require(wallet.publicKey)

        #expect(firstPublicKey != secondPublicKey)
    }

    @Test func signMessage() async throws {
        let connection = try #require(wallet.connection)
        let message = Data("Hello world".utf8)
        let signedMessage = try wallet.signMessage(message: message, display: .utf8)
        #expect(connection.privateKey.publicKey.isValidSignature(signedMessage.signature.bytes, for: message))
    }

    @Test func signTransaction() async throws {
        let connection = try #require(wallet.connection)

        let transaction = try Transaction(
            feePayer: connection.publicKey,
            blockhash: "HjtwhQ8dv67Uj9DCSWT8N3pgCuFpumXSk4ZyJk2EvwHk"
        ) {
            for i in 0..<3 {
                SystemProgram.transfer(
                    from: connection.publicKey,
                    to: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu", lamports: Int64(i))
            }
        }

        let signedTransaction = try wallet.signTransaction(transaction: transaction).transaction

        #expect(signedTransaction.message == transaction.message)
        #expect(signedTransaction.signatures.count == transaction.signatures.count)

        #expect(connection.privateKey.publicKey.isValidSignature(signedTransaction.signatures[0].bytes, for: try transaction.message.encode()))
    }

    @Test func isProbablyAvailable() {
        #expect(InMemoryWallet.isProbablyAvailable())
    }
}
