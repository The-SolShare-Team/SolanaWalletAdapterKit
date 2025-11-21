import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC
import SolanaTransactions

public struct DeeplinkWalletConnection: WalletConnection {
    public struct DiffieHellmanData: Codable {
        let publicKey: Data
        let privateKey: Data
        let sharedKey: Data

        public init(publicKey: Data, privateKey: Data, sharedKey: Data) {
            self.publicKey = publicKey
            self.privateKey = privateKey
            self.sharedKey = sharedKey
        }
    }

    public let session: String
    public let encryption: DiffieHellmanData
    public let walletPublicKey: PublicKey

    public init(
        session: String,
        encryption: DiffieHellmanData,
        walletPublicKey: PublicKey
    ) {
        self.session = session
        self.encryption = encryption
        self.walletPublicKey = walletPublicKey
    }
}
