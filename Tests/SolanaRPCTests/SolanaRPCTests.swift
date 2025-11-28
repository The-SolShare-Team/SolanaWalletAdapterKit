import Foundation
import Testing

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

// @Test func testGetBalanceNonExistentAccount() async throws {
//     let rpc = SolanaRPCClient(endpoint: .devnet)
//     let balance = try await rpc.getBalance(
//         account: "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG")
//     #expect(balance == 0)
// }

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

// @Test func testSendTransactionAndGetBalance() async throws {
//     let rpc = SolanaRPCClient(endpoint: .devnet)
//     let from: PublicKey = "CTZynpom8nofKjsdcYGTk3eWLpUeZQUvXd68dFphWKWu"
//     let to: PublicKey = "AWJ1WoX9w7hXQeMnaJTe92GHnBtCQZ5MWquCGDiZCqAG"

//     let recentBlockhashResponse = try await rpc.getLatestBlockhash()
//     let transaction = try Transaction(
//         feePayer: from,
//         blockhash: recentBlockhashResponse.blockhash
//     ) {
//         SystemProgram.transfer(
//             from: from,
//             to: to,
//             lamports: 1_000_000)
//     }

//     print(transaction)
//     let signature = try await rpc.sendTransaction(transaction: transaction)

//     let balance = try await rpc.getBalance(account: to)
//     #expect(balance == 2_000_000)

//     let fromBalance = try await rpc.getBalance(account: from)
//     #expect(fromBalance == 4_000_000)

//     //reverse transfer
//     let recentBlockhashResponse2 = try await rpc.getLatestBlockhash()
//     let reverseTransaction = try Transaction(
//         feePayer: to,
//         blockhash: recentBlockhashResponse2.blockhash
//     ) {
//         SystemProgram.transfer(
//             from: to,
//             to: from,
//             lamports: 1_000_000)
//     }

//     let reverseSignature: Signature = try await rpc.sendTransaction(transaction: reverseTransaction)
//     let reversedBalance = try await rpc.getBalance(account: to)
//     #expect(reversedBalance == 1_000_000)

//     let reversedFromBalance = try await rpc.getBalance(account: from)
//     #expect(reversedFromBalance == 5_000_000)

// }