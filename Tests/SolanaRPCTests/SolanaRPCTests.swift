import CryptoKit
import Foundation
import Testing
import SolanaWalletAdapterKit

@testable import SolanaRPC
@testable import SolanaTransactions

@Test func testGetBalance() async throws {
    let rpc = SolanaRPCClient(endpoint: .devnet)
    let balance = try await rpc.getBalance(
        account: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu")

    #expect(balance > 0)
    #expect(balance == 5000000000)
}

@Test func testGetBalanceWithConfig() async throws {
    let rpc = SolanaRPCClient(endpoint: .devnet)
    let config = SolanaRPCClient.GetBalanceConfiguration(commitment: .finalized)
    let balance = try await rpc.getBalance(
        account: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
        configuration: config)

    #expect(balance == 5000000000)

}

@Test func testGetLatestBlockhashAndGetBalance() async throws {
    let rpc = SolanaRPCClient(endpoint: .devnet)
    let blockhashResponse: SolanaRPCClient.GetLatestBlockhashResponse = try await rpc.getLatestBlockhash()
    let balance = try await rpc.getBalance(
        account: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu")
    #expect(balance == 5000000000)
    #expect(!(blockhashResponse.blockhash.bytes.count == 0))
}

@Test func testGetLatestBlockhashAndGetBalanceWithConfigs() async throws {
    let rpc = SolanaRPCClient(endpoint: .devnet)
    let blockhashConfig = SolanaRPCClient.GetLatestBlockhashConfiguration(commitment: .finalized)
    let blockhashResponse: SolanaRPCClient.GetLatestBlockhashResponse = try await rpc.getLatestBlockhash(
        configuration: blockhashConfig)
    let balanceConfig = SolanaRPCClient.GetBalanceConfiguration(commitment: .finalized)
    let balance = try await rpc.getBalance(
        account: "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu",
        configuration: balanceConfig)
    #expect(balance == 5000000000)
    #expect(!(blockhashResponse.blockhash.bytes.count == 0))
}

@Test func testGetMinBalanceForRentExemptionWithConfigs() async throws {
    let rpc = SolanaRPCClient(endpoint: .devnet)
    let lamports = try await rpc.getMinBalanceForRentExemption(
        accountDataLength: 165,
        configuration: SolanaRPCClient.GetMinBalanceForRentExemptionConfiguration(
            commitment: .finalized))
    #expect(lamports > 0)
}


@Test func testGetVersion () async throws {
    let rpc = SolanaRPCClient(endpoint: .devnet)
    let version = try await rpc.getVersion()
    #expect(!version.solanaCore.isEmpty)
}

@Test func testSendTransactionAndGetBalanceWithConfigs() async throws {
    let rpc = SolanaRPCClient(endpoint: .devnet)

    //pre generated for fixed wallets
    let from: PublicKey = "F2uuLHUzSKpj4EovSRsj8TD1wrrrhf4T3RUiDiCbDWj8"
    let fromPrivate: Curve25519.Signing.PrivateKey =  try Curve25519.Signing.PrivateKey(rawRepresentation: Data([231, 12, 103, 244, 166, 157, 71, 246, 
    216, 68, 185, 228, 138, 70, 224, 135, 81, 88, 99, 148, 89, 64, 21, 214, 73, 152, 101, 125, 37, 85, 204, 92]))
    print(fromPrivate.publicKey.rawRepresentation.base58EncodedString())
    let to: PublicKey = "4qgJqqCNopM68TwHnQTAy4gkYKV6LKW3oormkmyLgfZc"
    let toPrivate: Curve25519.Signing.PrivateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: Data([171, 58, 167, 227, 7, 
    198, 254, 179, 124, 122, 24, 196, 61, 59, 8, 137, 123, 40, 232, 180, 135, 59, 108, 80, 5, 147, 181, 168, 23, 223, 34, 213]))
    print(toPrivate.publicKey.rawRepresentation.base58EncodedString())

    let fromBefore = try await rpc.getBalance(account: from)
    try await Task.sleep(nanoseconds: 3_000_000_000)
    let toBefore = try await rpc.getBalance(account: to)
    try await Task.sleep(nanoseconds: 3_000_000_000)

    let recentBlockhash = try await rpc.getLatestBlockhash()
    let tx1 = try Transaction(
        feePayer: from,
        blockhash: recentBlockhash.blockhash
    ) {
        SystemProgram.transfer(from: from, to: to, lamports: 1_000_000_000)
    }

    let fromWallet = InMemoryWallet(for: .init(name: "TestApp", url: URL(string:"https://example.com")!, icon: "favicon.ico"), cluster: .devnet, connection: .init(privateKey: fromPrivate))
    let signed1 = try fromWallet.signTransaction(transaction: tx1)
    let _ = try await rpc.sendTransaction(transaction: signed1.transaction, configuration: SolanaRPCClient.SendTransactionConfiguration(encoding: .base58))
    try await Task.sleep(nanoseconds: 15_000_000_000)

    let fromAfter1 = try await rpc.getBalance(account: from)
    try await Task.sleep(nanoseconds: 3_000_000_000)
    let toAfter1 = try await rpc.getBalance(account: to)
    try await Task.sleep(nanoseconds: 3_000_000_000)

    #expect(toAfter1 == toBefore + 1_000_000_000)
    #expect(fromAfter1 <= fromBefore - 1_000_000_000) // fee + transfer

    let recentBlockhash2 = try await rpc.getLatestBlockhash()
    let tx2 = try Transaction(
        feePayer: to,
        blockhash: recentBlockhash2.blockhash
    ) {
        SystemProgram.transfer(from: to, to: from, lamports: 1_000_000_000)
    }

    let toWallet = InMemoryWallet(for: .init(name: "TestApp", url: URL(string:"https://example.com")!, icon: "favicon.ico"), cluster: .devnet, connection: .init(privateKey: toPrivate))
    let signed2: SignTransactionResponseData = try toWallet.signTransaction(transaction: tx2)
    let _ = try await rpc.sendTransaction(transaction: signed2.transaction)
    try await Task.sleep(nanoseconds: 15_000_000_000)

    let fromAfter2 = try await rpc.getBalance(account: from)
    try await Task.sleep(nanoseconds: 3_000_000_000)

    let toAfter2 = try await rpc.getBalance(account: to)
    try await Task.sleep(nanoseconds: 3_000_000_000)

    #expect(toAfter2 <= toAfter1 - 1_000_000_000)
    #expect(fromAfter2 >= fromAfter1 + 1_000_000_000)
}
