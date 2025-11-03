//
//  File.swift
//  SolanaWalletAdapterKit
//
//  Created by William Jin on 2025-11-02.
//

import Foundation
import CryptoKit
import SolanaRPC

public protocol BaseDeeplinkWallet: DeeplinkWallet {
    static var baseURL: URL { get }

    var connection: WalletConnection? { get set }
    var appId: AppIdentity { get set }
    var cluster: SolanaRPC.Endpoint { get set }
    var secureStorage: SecureStorage { get set }
    init()
    mutating func pair() async throws
}

// MARK: - Default Implementations
public extension BaseDeeplinkWallet {
    init(
        for appId: AppIdentity,
        cluster: SolanaRPC.Endpoint,
        restoreFrom secureStorage: SecureStorage
    ) async throws {
        self.init()
        self.appId = appId
        self.cluster = cluster
        self.secureStorage = secureStorage
        self.connection = try await secureStorage.retrieveWalletConnection(
            key: self.secureStorageKey)
    }
    
    

    mutating func pair() async throws {
        try await self.pair(walletEncryptionPublicKeyIdentifier: "solflare_encryption_public_key")
    }
}



