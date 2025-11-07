<<<<<<< HEAD:Sources/SolanaWalletAdapterKit/Wallets/Wallet.swift
import CryptoKit
public protocol Wallet {
    var isConnected: Bool { get set}
    var dappEncryptionPublicKey: Curve25519.KeyAgreement.PublicKey { get }
    var dappEncryptionSharedKey: SymmetricKey? { get set}
    mutating func connect(appUrl: String, redirectLink: String, cluster: String?) async throws
    func disconnect(nonce: String, redirectLink: String, payload: String) async throws
    
    func signAndSendTransaction(nonce: String, redirectLink: String, payload: String) async throws
    func signAllTransactions(nonce: String, redirectLink: String, payload: String) async throws
    func signTransaction(nonce: String, redirectLink: String, payload: String) async throws
    func signMessage(nonce: String, redirectLink: String, payload: String) async throws
    
    func browse(url: String, ref: String) async throws
=======
import Foundation
import SolanaRPC

public nonisolated protocol Wallet {
    init(for appId: AppIdentity, cluster: Endpoint)

    mutating func connect(appUrl: String, redirectLink: String, cluster: String?)
        async throws
    mutating func disconnect(nonce: String, redirectLink: String, payload: String)
        async throws

    nonmutating func signAndSendTransaction(
        nonce: String, redirectLink: String, payload: String)
        async throws
    nonmutating func signAllTransactions(
        nonce: String, redirectLink: String, payload: String)
        async throws
    nonmutating func signTransaction(
        nonce: String, redirectLink: String, payload: String)
        async throws
    nonmutating func signMessage(nonce: String, redirectLink: String, payload: String)
        async throws

    nonmutating func browse(url: URL, ref: String) async throws
>>>>>>> 4d7a344 (Using structs):Sources/SolanaWalletAdapterKit/Wallet.swift
}
