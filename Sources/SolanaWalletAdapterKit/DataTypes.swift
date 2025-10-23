//
//  File.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-17.
//

import Foundation

public protocol WalletResponse: Codable {}

struct ConnectResponse: WalletResponse {
    let encryptionPublicKey: Data
    let userPublicKey: String
    let session: String
    let nonce: String
}

struct SignAndSendTransactionResponse: WalletResponse {
    let nonce: String
    let signature: String
    
}

struct SignAllTransactionsResponse: WalletResponse {
    let nonce: String
    let transactions: [String]
    
}

struct SignTransactionResponse: WalletResponse {
    let nonce: String
    let transaction: String
   
}
// for messages

struct SignMessageResponse: WalletResponse {
    let nonce: String
    let signature: String
}

public enum EncodingFormat: String {
    case hex = "hex"
    case utf8 = "utf-8"
}

// SendOptions type based on https://solana-foundation.github.io/solana-web3.js/types/SendOptions.html
public struct SendOptions: Codable {
    public let maxRetries: Int?
    public let minContextSlot: Int?
    public let preflightCommitment: Commitment?
    public let skipPreflight: Bool?
}

public enum Commitment: String, Codable {
    case processed
    case confirmed
    case finalized
    case recent
    case single
    case singleGossip
    case root
    case max
}

// factory class provider enum

public enum WalletProvider: String {
    case backpack
    case phantom
    case solflare
    init?(input: String) {
        switch input.lowercased() {
        case "backpack", "bp": self = .backpack
        case "phantom", "ph": self = .phantom
        case "solflare", "sf": self = .solflare
        default: return nil
        }
    }
    
}
