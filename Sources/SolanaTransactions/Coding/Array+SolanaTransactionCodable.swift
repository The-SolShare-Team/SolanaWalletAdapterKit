extension Array: SolanaTransactionCodable where Element: SolanaTransactionCodable {
    init(fromSolanaTransaction buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        let count = Int(try UInt16(fromSolanaTransaction: &buffer))
        do {
            try self.init(unsafeUninitializedCapacity: count) { array, initializedCount in
                for i in 0..<count {
                    defer { initializedCount += 1 }
                    array[i] = try Element(fromSolanaTransaction: &buffer)
                }
            }
        } catch {
            // swiftlint:disable:next force_cast
            throw error as! SolanaTransactionCodingError
        }
    }

    func solanaTransactionEncode(to buffer: inout SolanaTransactionBuffer)
        throws(SolanaTransactionCodingError)
    {
        try UInt16(self.count).solanaTransactionEncode(to: &buffer)
        for el in self {
            try el.solanaTransactionEncode(to: &buffer)
        }
    }
}
