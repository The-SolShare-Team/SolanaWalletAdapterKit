<<<<<<< HEAD
/// Struct to group related addresses so they can be fetched efficiently within a single transaction.
///
/// See [Solana Documentation on Address Table Lookups](https://solana.com/developers/guides/advanced/lookup-tables) for more details.
=======
/// Create  a collection of related addresses to efficiently load more addresses in a single transaction.
///
/// Address Lookup Tables, commonly referred to as "lookup tables" or "ALTs" for short, allow developers to create a collection of related addresses to efficiently load more addresses in a single transaction.
///
/// Since each transaction on the Solana blockchain requires a listing of every address that is interacted with as part of the transaction, this listing would effectively be capped at 32 addresses per transaction. With the help of `AddressTableLookup`, a transaction would now be able to raise that limit to 64 addresses per transaction.
///
/// See [Solana Documentation](https://solana.com/developers/guides/advanced/lookup-tables) for more details.
>>>>>>> 656e57b (finished SolanaTransactions)
///
/// ```
/// public init(account: PublicKey, writableIndexes: [UInt8],
/// readOnlyIndexes: [UInt8]) {
///     self.account = account
///     self.writableIndexes = writableIndexes
///     self.readOnlyIndexes = readOnlyIndexes
///}
/// ```
/// - Parameters:
///   - account: The public key of the address table account on the Solana blockchain.
///   - writableIndexes:Indexes of writable accounts within the address table that the transaction can modify
///   - readOnlyIndexes: Indexes of read-only accounts within the address table that the transaction can read.
///
public struct AddressTableLookup: Equatable, Sendable {
    public let account: PublicKey
    public let writableIndexes: [UInt8]
    public let readOnlyIndexes: [UInt8]

    public init(account: PublicKey, writableIndexes: [UInt8], readOnlyIndexes: [UInt8]) {
        self.account = account
        self.writableIndexes = writableIndexes
        self.readOnlyIndexes = readOnlyIndexes
    }
}

extension AddressTableLookup: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        account = try PublicKey(fromSolanaTransaction: &buffer)
        writableIndexes = try [UInt8].init(fromSolanaTransaction: &buffer)
        readOnlyIndexes = try [UInt8].init(fromSolanaTransaction: &buffer)
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        try account.solanaTransactionEncode(to: &buffer)
        try writableIndexes.solanaTransactionEncode(to: &buffer)
        try readOnlyIndexes.solanaTransactionEncode(to: &buffer)
    }
}
