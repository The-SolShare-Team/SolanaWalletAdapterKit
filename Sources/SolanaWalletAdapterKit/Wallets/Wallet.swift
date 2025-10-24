import CryptoKit
import Foundation
public protocol Wallet {
    var dappEncryptionPublicKey: Curve25519.KeyAgreement.PublicKey {get set}
    var provider: WalletProvider {get set}
    
    // each provider function for our wallet builds and returns a URL that is called using an adapter in the Demo App
    // things to maybe change:
    //      function names may be kind of ambiguous in that they are not actually opening the URL, but only returning it
    //      
    
    func connect(appUrl: String, redirectLink: String, cluster: String?) async throws -> URL
    func disconnect(redirectLink: String) async throws -> URL
    
    func signAndSendTransaction(redirectLink: String, transaction: Data, sendOptions: SendOptions?) async throws -> URL
    func signAllTransactions(redirectLink: String, transactions: [Data]) async throws -> URL
    func signTransaction(redirectLink: String, transaction: Data) async throws -> URL
    func signMessage(redirectLink: String, message: String, encodingFormat: EncodingFormat?) async throws -> URL
    
    func browse(url: String, ref: String) async throws -> URL
    
    
    // corresponding redirect handlers for each universal link URL builder function, for when returning to the app
    
    func handleConnectRedirect(_ url: URL) async throws -> ConnectResponse
    func handleDisconnectRedirect(_ url: URL) async throws -> Void
    func handleSignAndSendTransactionRedirect(_ url: URL) async throws -> SignTransactionResponse
    func handleSignAllTransactionsRedirect(_ url: URL) async throws -> SignAllTransactionsResponse
    func handleSignTransactionRedirect(_ url: URL) async throws -> SignTransactionResponse
    func handleSignMessageRedirect(_ url: URL) async throws -> SignMessageResponse
    
    
}
