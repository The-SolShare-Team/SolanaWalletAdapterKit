import SolanaRPC

// SendOptions type based on https://solana-foundation.github.io/solana-web3.js/types/SendOptions.html
public struct SendOptions: Codable {
    public let maxRetries: Int?
    public let minContextSlot: Int?
    public let preflightCommitment: Commitment?
    public let skipPreflight: Bool?
}

public enum MessageDisplayFormat: String {
    case hex = "hex"
    case utf8 = "utf-8"
}
