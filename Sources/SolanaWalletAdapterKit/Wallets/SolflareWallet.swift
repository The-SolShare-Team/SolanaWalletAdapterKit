struct SolflareWallet: Wallet {
    var dappEncryptionPublicKey: String
    
    func connect(appUrl: String, redirectLink: String, cluster: String?) async throws {
        // Implementation
    }
    func disconnect(nonce: String, redirectLink: String, payload: String) async throws{
        // Implementation
    }
    
    func signAndSendTransaction(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    func signAllTransactions(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    func signTransaction(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    func signMessage(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    
    func browse(url: String, ref: String) async throws {
        // Implementation
    }
}
