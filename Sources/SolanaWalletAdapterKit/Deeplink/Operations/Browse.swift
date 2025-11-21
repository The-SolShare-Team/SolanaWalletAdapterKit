import Base58
import CryptoKit
import Foundation
import Salt
import Security
import SimpleKeychain
import SolanaRPC
import SolanaTransactions

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

extension DeeplinkWallet {
    /// Browse to a URL.
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
            return components.url!  // TODO: Is it safe to force unwrap here?
        }()

        #if os(iOS)
            let success = await UIApplication.shared.open(deeplink)
            if !success { throw DeeplinkFetchingError.unableToOpen }  // TODO: Not sure about this error
        #elseif os(macOS)
            let success = NSWorkspace.shared.open(deeplink)
            if !success { throw DeeplinkFetchingError.unableToOpen }  // TODO: Not sure about this error
        #endif
    }
}
