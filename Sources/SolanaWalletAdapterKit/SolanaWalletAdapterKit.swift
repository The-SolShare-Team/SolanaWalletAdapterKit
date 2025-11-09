import Foundation

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

    public static func registerCallbackScheme(_ scheme: String) {
        _fetcher = DeeplinkFetcher(scheme: scheme)
    }

    public static func handleOnOpenURL(_ url: URL) -> Bool {
        return fetcher.handleCallback(url)
    }

    public static func deeplinkFetch(
        _ url: URL, callbackParameter: String, timeout: TimeInterval = 30.0
    )
        async throws(DeeplinkFetchingError) -> [String: String]
    {
        try await fetcher.fetch(url, callbackParameter: callbackParameter, timeout: timeout)
    }
}
