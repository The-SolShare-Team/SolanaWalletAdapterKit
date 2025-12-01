import Foundation

extension DeeplinkWallet {
    /// Sends a disconnect request to the wallet.
    ///
    /// - Throws:
    ///   - `SolanaWalletAdapterError` if the deep link request fails,
    ///     if the wallet returns an error response, or if the callback payload
    ///     is invalid.
    public mutating func disconnect() async throws {
        let connection = try _activeConnection

        let endpointURL: URL = Self._deeplinkWalletOptions.baseURL.appendingPathComponent(
            "disconnect")

        // Request
        let payload = DisconnectRequestPayload(session: connection.session)
        let deeplink = try generateNonConnectDeeplinkURL(
            endpointUrl: endpointURL, payload: payload)

        // Response
        let response = try await SolanaWalletAdapter.deeplinkFetch(
            deeplink, callbackParameter: "redirect_link")
        try throwIfErrorResponse(response: response)
        self.connection = nil
    }
}
