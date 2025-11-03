import Foundation


@MainActor
let solana = SolanaWalletAdapter(callbackScheme: "solanaMWADemo://")

@MainActor
public protocol DeeplinkWallet: Wallet {
    var baseURL: URL { get }
    var cluster: Cluster { get set } 
}

public extension DeeplinkWallet {
    func generateConnectUrl(_ appUrl: String, _ redirectLink: String, _ cluster: String? = nil) throws -> URL{
        var params: [String: String?] = [
                    "app_url": appUrl,
                    "dapp_encryption_public_key": Utils.base58Encode(dappEncryptionPublicKey.rawRepresentation),
//                    "redirect_link": redirectLink,
        ] //query string params for connect()  https://docs.backpack.app/deeplinks/provider-methods/connect
        if let clust = cluster {
            params["cluster"] = clust
        }
        guard let url = Utils.buildURL(baseURL: "\(baseURL.absoluteString)/connect", queryParams: params) else {
            throw WalletAdapterError.urlBuildFailed(baseURL: baseURL.absoluteString)
        }
        return url
    }
    mutating func connect(appUrl: String, redirectLink: String, cluster: String? = nil) async throws {
        let clusterToUse = cluster ?? self.cluster.rawValue
        let connectUrl = try generateConnectUrl(appUrl, redirectLink) // add cluster later
        
        
        print(try await solana.fetcher.fetch(connectUrl, callbackParameter: "redirect_link"))
        isConnected = true
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

public enum Cluster: String {
    case mainnet = "mainnet-beta"
    case devnet = "devnet"
    case testnet = "testnet"
}
