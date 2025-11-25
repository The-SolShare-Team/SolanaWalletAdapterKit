import Foundation

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

extension DeeplinkWallet {
    @MainActor
    public func browse(url: URL, ref: URL) async throws {
        guard
            let encodedTargetURL = url.absoluteString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed),
            let encodedRefURL = ref.absoluteString.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed)
        else {
            throw SolanaWalletAdapterError.invalidRequest
        }

        let deeplink = try {
            let endpointURL = Self._deeplinkWalletOptions.baseURL.appendingPathComponent("browse")
            guard
                var components = URLComponents(
                    url: endpointURL.appendingPathComponent(encodedTargetURL),
                    resolvingAgainstBaseURL: false)
            else {
                throw SolanaWalletAdapterError.invalidRequest
            }
            components.queryItems = [
                URLQueryItem(name: "ref", value: encodedRefURL)
            ]
            return components.url!
        }()
        #if os(iOS)
            let success = await UIApplication.shared.open(deeplink)
        #elseif os(macOS)
            let success = NSWorkspace.shared.open(deeplink)
        #endif
        if !success { throw SolanaWalletAdapterError.browsingFailure }
    }
}
