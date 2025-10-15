protocol Wallet {
    var dappEncryptionPublicKey: String { get set }
    
    func connect(appUrl: String, redirectLink: String, cluster: String?) async throws
    func disconnect(nonce: String, redirectLink: String, payload: String) async throws
    
    func signAndSendTransaction(nonce: String, redirectLink: String, payload: String) async throws
    func signAllTransactions(nonce: String, redirectLink: String, payload: String) async throws
    func signTransaction(nonce: String, redirectLink: String, payload: String) async throws
    func signMessage(nonce: String, redirectLink: String, payload: String) async throws
    
    func browse(url: String, ref: String) async throws
}
