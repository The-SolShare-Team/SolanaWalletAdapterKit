import SolanaTransactions

extension Blockhash: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let value = Self(base58EncodedString: string) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid Base58 blockhash: \(string)")
        }
        self = value
    }
}
