import Foundation

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

public enum DeeplinkFetchingError: Error {
    case timeout
    case unableToOpen
    case decodeError
}

@MainActor
class DeeplinkFetcher {
    let scheme: String

    init(scheme: String) {
        self.scheme = scheme
    }

    private var pendingRequests: [UUID: PendingRequest] = [:]

    private struct PendingRequest {
        let continuation: CheckedContinuation<Result<URLComponents, DeeplinkFetchingError>, Never>
        let timeoutTask: Task<Void, Never>
    }

    @available(iOS 16.0, macOS 13.0, *)
    func fetch(_ url: URL, callbackParameter: String, timeout: Duration)
        async throws(DeeplinkFetchingError) -> [String: String]
    {
        try await fetch(
            url, callbackParameter: callbackParameter,
            timeout: Double(timeout.components.seconds) + Double(timeout.components.attoseconds)
                / 1_000_000_000_000_000_000)
    }

    func fetch(_ url: URL, callbackParameter: String, timeout: TimeInterval = 30.0)
        async throws(DeeplinkFetchingError) -> [String: String]
    {
        let id = UUID()
        let callbackURL = "\(scheme):\(id.uuidString)"

        let finalURL = {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            var queryItems = components.queryItems ?? []
            queryItems.append(URLQueryItem(name: callbackParameter, value: callbackURL))
            components.queryItems = queryItems
            return components.url!
        }()

        let result = await withCheckedContinuation {
            (continuation: CheckedContinuation<Result<URLComponents, DeeplinkFetchingError>, Never>)
            in
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64((timeout * 1_000_000_000).rounded()))
                continuation.resume(returning: .failure(.timeout))
            }

            pendingRequests[id] = PendingRequest(
                continuation: continuation, timeoutTask: timeoutTask)

            #if os(iOS)
                let success = await UIApplication.shared.open(finalURL)
            #elseif os(macOS)
                let success = NSWorkspace.shared.open(finalURL)
            #endif

            if !success {
                continuation.resume(returning: .failure(.unableToOpen))
            }
        }

        switch result {
        case .failure(let cause): throw cause
        case .success(let components):
            let urlQueryItems = components.queryItems ?? []
            let queryParams: [String: String] = Dictionary(
                uniqueKeysWithValues: urlQueryItems.map { ($0.name, $0.value ?? "") })
            return queryParams
        }
    }

    func handleCallback(_ url: URL) -> Bool {
        guard url.scheme == scheme else { return false }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        if let id = UUID(uuidString: url.lastPathComponent),
            let request = pendingRequests.removeValue(forKey: id)
        {
            request.timeoutTask.cancel()
            request.continuation.resume(returning: .success(components))
        }

        return true
    }
}
