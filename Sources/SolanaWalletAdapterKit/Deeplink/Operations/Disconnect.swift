import Foundation

extension DeeplinkWallet {
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
