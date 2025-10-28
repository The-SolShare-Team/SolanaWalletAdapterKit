import Foundation

struct SolflareWallet: DeeplinkWallet {
    let baseURL = URL(string: "https://solflare.com/ul/v1")!
    var dappEncryptionPublicKey = "test"

    func signAndSendTransaction(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
}
