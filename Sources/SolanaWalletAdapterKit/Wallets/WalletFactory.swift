//
//  File.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-10-21.
//

import Foundation
import SolanaKit
import CryptoKit
import TweetNacl

public class WalletFactory {
    public static func createWallet(provider: WalletProvider, privateKey: Curve25519.KeyAgreement.PrivateKey? = nil) -> Wallet? {
        switch provider.rawValue{
        case "backpack": return BackpackWallet(privateKey: privateKey)
            // add other providers when finished implementation
        default: return nil
        }
    }
}
