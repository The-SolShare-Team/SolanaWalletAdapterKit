import Foundation

/// A static utility that provides core functionality for interacting with deeplink-based Solana wallets.
@MainActor
public enum SolanaWalletAdapter {
    private static var _fetcher: DeeplinkFetcher?
    private static var fetcher: DeeplinkFetcher {
        guard let fetcher = _fetcher else {
            fatalError(
                "SolanaWalletAdapter not initialized. Call registerCallbackScheme(_:) first.")
        }
        return fetcher
    }

    /// Initializes the SolanaWalletAdapter with a callback URL scheme.
    ///
    /// - Parameter scheme: The URL scheme registered by the app
    /// - Important: Calling this method multiple times will trigger a runtime `fatalError`.
    public static func registerCallbackScheme(_ scheme: String) {
        if _fetcher != nil {
            fatalError(
                "SolanaWalletAdapter already initialized. Call registerCallbackScheme(_:) only once."
            )
        }
        _fetcher = DeeplinkFetcher(scheme: scheme)
    }

    /// Handles an incoming URL that the system opens for the app, typically from a wallet deeplink.
    ///
    /// - Parameter url: The URL opened by the system.
    /// - Returns: `true` if the URL was successfully handled as a wallet callback; `false` otherwise.
    public static func handleOnOpenURL(_ url: URL) -> Bool {
        return fetcher.handleCallback(url)
    }

    /// Performs a deeplink fetch request and waits for a response from the wallet.
    ///
    /// - Parameters:
    ///   - url: The deeplink URL to open in the wallet.
    ///   - callbackParameter: The query parameter name used by the wallet to return the redirect URL
    ///   - timeout: Maximum time in seconds to wait for a response from the wallet. Defaults to `30` seconds.
    /// - Throws: `DeeplinkFetchingError` if the request times out, cannot open the wallet, or the response cannot be decoded.
    /// - Returns: A dictionary of response key/value pairs returned by the wallet.
    public static func deeplinkFetch(
        _ url: URL, callbackParameter: String, timeout: TimeInterval = 30.0
    )
        async throws(DeeplinkFetchingError) -> [String: String]
    {
        try await fetcher.fetch(url, callbackParameter: callbackParameter, timeout: timeout)
    }
}
