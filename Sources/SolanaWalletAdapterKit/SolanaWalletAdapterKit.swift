import Foundation

public class SolanaWalletAdapter : ObservableObject {
    public var fetcher: DeeplinkFetcher
    @MainActor
    public init(callbackScheme: String) {
        fetcher = DeeplinkFetcher(scheme: callbackScheme)
    }

    @MainActor
    public func handleOnOpenURL(_ url: URL) -> Bool {
        return fetcher.handleCallback(url)
    }
}
