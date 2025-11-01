import Foundation

public class SolanaWalletAdapter {
    public var fetcher: DeeplinkFetcher

    public init(callbackScheme: String) {
        fetcher = DeeplinkFetcher(scheme: callbackScheme)
    }

    @MainActor
    public func handleOnOpenURL(_ url: URL) -> Bool {
        return fetcher.handleCallback(url)
    }
}
