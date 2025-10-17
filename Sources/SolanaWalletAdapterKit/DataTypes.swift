//
//  File.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-17.
//

import Foundation


struct ConnectResponse {
    let encryptionPublicKey: String
    let userPublicKey: String
    let session: String
    let nonce: String
}

struct SignAndSendTransactionResponse {
    let signature: String
    let nonce: String
}

struct SignAllTransactionsResponse {
    let transactions: [String]
    let nonce: String
}

struct SignTransactionResponse {
    let transaction: String
    let nonce: String
}
