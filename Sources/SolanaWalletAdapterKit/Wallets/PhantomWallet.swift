import CryptoKit
public struct PhantomWallet: Wallet {
    public var isConnected: Bool
    
    public var dappEncryptionPublicKey: Curve25519.KeyAgreement.PublicKey
    
    public var dappEncryptionSharedKey: SymmetricKey?
    
    public func connect(appUrl: String, redirectLink: String, cluster: String?) async throws {
        // Implementation
    }
    public func disconnect(nonce: String, redirectLink: String, payload: String) async throws{
        // Implementation
    }
    
    public func signAndSendTransaction(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    public func signAllTransactions(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    public func signTransaction(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    public func signMessage(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    
    public func browse(url: String, ref: String) async throws {
        // Implementation
    }
}
