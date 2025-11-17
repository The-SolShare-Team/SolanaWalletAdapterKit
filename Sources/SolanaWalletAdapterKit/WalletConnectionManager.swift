struct WalletConnectionManager {
    public var wallets: [any Wallet.Type]

    public func identifier(for wallet: any Wallet) -> String {
        var hasher = Hasher()
        let identifier = type(of: wallet).identifier
        hasher.combine(identifier)
        hasher.combine(wallet.appId)
        hasher.combine(wallet.cluster)
        return String(hasher.finalize())
    }
}
