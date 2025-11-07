import Foundation

public nonisolated protocol Wallet {
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
}
