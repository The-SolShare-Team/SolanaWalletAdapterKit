import CryptoKit
import Foundation
protocol Wallet {
    var dappEncryptionPublicKey: Curve25519.KeyAgreement.PublicKey {get set}
    
    
    func connect(appUrl: String, redirectLink: String, cluster: String?) async throws -> URL
    func disconnect(redirectLink: String) async throws -> URL
    
    func signAndSendTransaction(redirectLink: String, transaction: Data, sendOptions: SendOptions?) async throws -> URL
    func signAllTransactions(redirectLink: String, transactions: [Data]) async throws -> URL
    func signTransaction(redirectLink: String, transaction: Data) async throws -> URL
    func signMessage(redirectLink: String, message: String, encodingFormat: EncodingFormat?) async throws -> URL
    
    func browse(url: String, ref: String) async throws -> URL
}
