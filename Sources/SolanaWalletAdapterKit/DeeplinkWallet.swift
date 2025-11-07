import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC

public protocol DeeplinkWallet: Wallet {
    static var baseURL: URL { get }
    var encryption: DiffieHellman { get set }
}

public struct DiffieHellman {
    let encryptionKeyPair: (publicKey: Data, secretKey: Data)
    let sharedKey: Data
}

public struct KeyPair {
    let publicKey: Data
    let secretKey: Data
}

extension DeeplinkWallet {
    init(for appId: AppIdentity, cluster: Endpoint) {
        let keychain = SimpleKeychain(service: appId.name)  // TODO: Expose keychain options

        let kPub = "encryptionPublicKey"
        let kSec = "encryptionSecretKey"
        let kShared = "encryptionSharedKey"
        let kSession = "session"
        let kPublicKey = "publicKey"

        do {
            let encryptionPublicKey = try keychain.data(forKey: kPub)
            let encryptionSecretKey = try keychain.data(forKey: kSec)

            self.encryptionKey = KeyPair(
                publicKey: encryptionPublicKey,
                secretKey: encryptionSecretKey
            )
            self.sharedKey = try keychain.data(forKey: kShared)
            self.session = try? keychain.string(forKey: kSession)
            self.publicKey = try? keychain.string(forKey: kPublicKey)
        } catch {
            // On any error (including partial state), clear possible partial entries and recreate keys.
            clearKeypairFromKeychain()

            if let kp = try? SaltBox.keyPair() {
                self.encryptionKeyPair = kp
                // Best-effort persistence; failures should not crash the app.
                try? keychain.set(kp.publicKey, forKey: kPub)
                try? keychain.set(kp.secretKey, forKey: kSec)
            } else {
                // As an unlikely fallback, initialize with empty Data to keep object in a valid state.
                self.encryptionKeyPair = (publicKey: Data(), secretKey: Data())
            }

            // Reset optional values — they'll be set when the session is established.
            self.encryptionSharedKey = nil
            self.session = nil
            self.publicKey = nil
        }

        if let encryptionPublicKey = try? keychain.data(forKey: "encryptionPublicKey"),
            let encryptionSecretKey = try? keychain.data(forKey: "encryptionSecretKey"),
            let session = try? keychain.string(forKey: "session"),
            let encryptionSharedKey = try? keychain.data(forKey: "encryptionSharedKey"),
            let publicKey = try? keychain.string(forKey: "publicKey")
        {
            self.encryptionKeyPair = (
                publicKey: encryptionPublicKey, secretKey: encryptionSecretKey
            )
            self.encryptionSharedKey = encryptionSharedKey
            self.session = session
            self.publicKey = publicKey
        } else {
            self.encryptionKeyPair = try! SaltBox.keyPair()
            try! keychain.set(self.encryptionKeyPair.publicKey, forKey: "encryptionPublicKey")
            try! keychain.set(self.encryptionKeyPair.secretKey, forKey: "encryptionSecretKey")
        }
    }

    public func connect(appUrl: String, redirectLink: String, cluster: String?)
        async throws
    {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()

        let connectURL = "connect"
        var params: [String: String?] = [
            "app_url": appUrl,
            "dapp_encryption_public_key": Base58.encode(dappEncryptionPublicKey.rawRepresentation),
            "redirect_link": redirectLink,
        ]
        if let clust = cluster {
            params["cluster"] = clust
        }
        guard let url = Utils.buildURL(baseURL: connectURL, queryParams: params) else {
            throw NSError(
                domain: "BackpackWallet", code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to build URL"])
        }
        return url

        // let a = try await SolanaWalletAdapter.deeplinkFetch(
        //     Self.baseURL, callbackParameter: "redirect_link")
    }
    public func disconnect(nonce: String, redirectLink: String, payload: String)
        async throws
    {
        // Implementation
    }

    public func signAllTransactions(
        nonce: String, redirectLink: String, payload: String
    )
        async throws
    {
        // Implementation
    }
    public func signAndSendTransaction(
        nonce: String, redirectLink: String, payload: String
    )
        async throws
    {
        // Implementation
    }
    public func signTransaction(nonce: String, redirectLink: String, payload: String)
        async throws
    {
        // Implementation
    }
    public func signMessage(nonce: String, redirectLink: String, payload: String)
        async throws
    {
        // Implementation
    }

    public func browse(url: URL, ref: String) async throws {
        // Implementation
    }
}
