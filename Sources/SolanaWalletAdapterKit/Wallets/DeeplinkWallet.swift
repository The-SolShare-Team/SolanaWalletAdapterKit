import Foundation

let solana = SolanaWalletAdapter(callbackScheme: "myscheme")

protocol DeeplinkWallet: Wallet {
    var baseURL: URL { get }
}

extension DeeplinkWallet {
    func connect(appUrl: String, redirectLink: String, cluster: String?) async throws {
        print(try await solana.fetcher.fetch(baseURL, callbackParameter: "redirect_link"))
    }

    func disconnect(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }

    func signAllTransactions(nonce: String, redirectLink: String, payload: String) async throws {
        // Implementation
    }
    func signAndSendTransaction(nonce: String, redirectLink: String, payload: String) async throws {
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
