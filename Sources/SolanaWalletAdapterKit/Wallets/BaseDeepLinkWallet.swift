//
//  File.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-11-02.
//

import Foundation
import CryptoKit

// Write the key logic ONCE
open class BaseDeeplinkWallet: @MainActor DeeplinkWallet, ObservableObject {
    open var baseURL: URL {
        fatalError("Subclasses must override baseURL")
    }
    public var dappEncryptionPrivateKey: Curve25519.KeyAgreement.PrivateKey
    public var dappEncryptionPublicKey: Curve25519.KeyAgreement.PublicKey
    public var dappEncryptionSharedKey: SymmetricKey?
    @Published public var isConnected: Bool = false
    public var dappUserPublicKey: String?
    public var session: String?
    public var cluster: Cluster
    // Initialization logic written ONCE
    public init(cluster: Cluster = .devnet, privateKey: Curve25519.KeyAgreement.PrivateKey? = nil) {
        self.cluster = cluster
        
        if let privKey = privateKey {
            self.dappEncryptionPrivateKey = privKey
        } else {
            self.dappEncryptionPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        }
        self.dappEncryptionPublicKey = dappEncryptionPrivateKey.publicKey
    }
    
    
}



