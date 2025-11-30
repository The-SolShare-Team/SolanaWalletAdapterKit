import CryptoKit
// import Foundation
// import SolanaRPC
// import SolanaTransactions
// import SwiftBorsh
// import Testing

// @testable import SolanaTransactions

// @Test func createATAAndVerify() async throws {

//     print("Starting Associated Token Account Test")
//     //generate mint account and owner account
//     let mintPrivateKey = Curve25519.Signing.PrivateKey()
//     guard let mintPublicKey = PublicKey(bytes: [UInt8](mintPrivateKey.publicKey.rawRepresentation))
//     else {
//         fatalError("Failed to create mint public key")
//     }

//     let mintAuthorityPrivateKey = Curve25519.Signing.PrivateKey()
//     guard
//         let mintAuthorityPublicKey = PublicKey(
//             bytes: [UInt8](mintAuthorityPrivateKey.publicKey.rawRepresentation))
//     else {
//         fatalError("Failed to create mint authority public key")
//     }

//     let ownerPrivateKey = Curve25519.Signing.PrivateKey()
//     guard
//         let ownerPublicKey = PublicKey(bytes: [UInt8](ownerPrivateKey.publicKey.rawRepresentation))
//     else {
//         fatalError("Failed to create owner public key")
//     }

//     print("Mint Public Key: \(mintPublicKey)")
//     let rpc = SolanaRPCClient(endpoint: .devnet)

//     print("DEBUG: Created RPC Client")
//     //find asscoiated token account
//     let associatedTokenAccount = try await ProgramDerivedAddress.find(
//         programId: AssociatedTokenProgram.programId,
//         seeds: [
//             ownerPublicKey.bytes,
//             TokenProgram.programId.bytes,
//             mintPublicKey.bytes,
//         ]
//     )

//     //airdrop to mint authority and owner
//     // print("DEBUG: Requesting Airdrops")
//     // let airdropAmount = 2_000_000_000
//     // try await rpc.requestAirdrop(to: mintAuthorityPublicKey, lamports: UInt64(airdropAmount))
//     // try await rpc.requestAirdrop(to: ownerPublicKey, lamports: UInt64(airdropAmount))

//     //get rent exempt balance and recent blockhash
//     let rentExemptBalanceResponse = try await rpc.getMinBalanceForRentExemption(
//         accountDataLength: 82)
//     var blockhashResponse = try await rpc.getLatestBlockhash()

//     print("DEBUG: Got Blockhash \(blockhashResponse.blockhash)")
//     let createAndInitializeMintTransaction = try! Transaction(
//         blockhash: blockhashResponse.blockhash
//     ) {
//         SystemProgram.createAccount(
//             from: mintAuthorityPublicKey,
//             newAccount: mintPublicKey,
//             lamports: Int64(rentExemptBalanceResponse),
//             space: 82,
//             programId: TokenProgram.programId
//         )
//         TokenProgram.initializeMint(
//             mintAccount: mintPublicKey,
//             decimals: 0,
//             mintAuthority: mintAuthorityPublicKey,
//             freezeAuthority: nil
//         )
//     }

//     print("DEBUG: Created Mint Transaction")
//     try await rpc.sendTransaction(
//         transaction: createAndInitializeMintTransaction,
//         options: TransactionOptions(
//             skipPreflight: true,
//             preflightCommitment: .confirmed
//         ))

//     print("DEBUG: Sent Mint Transaction")
//     blockhashResponse = try await rpc.getLatestBlockhash()
//     let ataInstructions = try AssociatedTokenProgram.createAssociatedTokenAccount(
//         mint: mintPublicKey,
//         associatedAccount: associatedTokenAccount.publicKey,
//         owner: ownerPublicKey,
//         payer: ownerPublicKey,
//         associatedProgramId: AssociatedTokenProgram.programId,
//         tokenProgramId: TokenProgram.programId
//     )

//     let buildATATransaction = try Transaction(blockhash: blockhashResponse.blockhash) {
//         ataInstructions
//     }

//     print("DEBUG: Created ATA Transaction")
//     try await rpc.sendTransaction(
//         transaction: buildATATransaction,
//         options: TransactionOptions(
//             skipPreflight: true,
//             preflightCommitment: .confirmed
//         ))

//     print("DEBUG: Sent ATA Transaction")
//     let accountInfo: AccountInfoResult?
//     do {
//         accountInfo = try await rpc.getAccountInfo(
//             for: associatedTokenAccount.publicKey,
//             config: AccountInfoConfig(commitment: .confirmed)
//         )
//     } catch {
//         Issue.record("RPC call failed: \(error)")
//         return
//     }

//     guard let account = accountInfo else {
//         Issue.record("Account info was nil — account may not exist yet")
//         return
//     }

//     #expect(account.space == 165)

// }
