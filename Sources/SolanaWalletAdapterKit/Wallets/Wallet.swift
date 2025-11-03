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
}
