protocol Wallet {
    var dappEncryptionPublicKey: String { get set }
    
    func connect(appUrl: String, redirectLink: String, cluster: String?)
    func disconnect(nonce: String, redirectLink: String, payload: String)
    
    func signAndSendTransaction(nonce: String, redirectLink: String, payload: String)
    func signAllTransactions(nonce: String, redirectLink: String, payload: String)
    func signTransaction(nonce: String, redirectLink: String, payload: String)
    func signMessage(nonce: String, redirectLink: String, payload: String)
    
    func browse(url: String, ref: String)
}
