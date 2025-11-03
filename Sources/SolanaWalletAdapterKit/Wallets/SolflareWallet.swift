import Foundation

public class SolflareWallet: BaseDeeplinkWallet {
    public override var baseURL: URL {
        URL(string: "https://solflare.com/ul/v1")!
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
