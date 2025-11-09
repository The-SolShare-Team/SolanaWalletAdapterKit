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
        let continuation: CheckedContinuation<URLComponents, Error>
        let timeoutTask: DispatchWorkItem
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
        let callbackURL = "\(scheme)://\(id.uuidString)"
        
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
                continuation: continuation,
                timeoutTask: workItem
            )
            print("[DeeplinkFetcher] Current pending UUIDs after registration: \(pendingRequests.keys)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: workItem)
            // Open the URL after everything is registered
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds delay
            #if os(iOS)
                UIApplication.shared.open(finalURL) { [self] success in
                    if !success {
                        if let request = pendingRequests.removeValue(forKey: id) {
                            request.timeoutTask.cancel()
                            request.continuation.resume(throwing: DeeplinkFetchingError.unableToOpen)
                        }
                    }
                }
            #elseif os(macOS)
                let success = NSWorkspace.shared.open(finalURL)
            #endif
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
        print("[DeeplinkFetcher] handleCallback called with URL: \(url.absoluteString)")

        guard url.scheme == scheme else { return false }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("[DeeplinkFetcher] Failed to parse URL components")
            return false
        }
        guard let idString = url.host else {
            print("[DeeplinkFetcher] URL host is missing: \(url.absoluteString)")
            return false
        }
        guard let id = UUID(uuidString: idString) else {
            print("[DeeplinkFetcher] Failed to extract UUID from URL lastPathComponent: \(url.lastPathComponent)")
            return false
        }
        print("[DeeplinkFetcher] Pending UUIDs before removing: \(pendingRequests.keys)")

        guard let request = pendingRequests.removeValue(forKey: id) else {
            print("[DeeplinkFetcher] No pending request found for UUID: \(id)")
            return false
        }

        print("[DeeplinkFetcher] Found pending request, resuming continuation and cancelling timeout")
        request.timeoutTask.cancel()
        request.continuation.resume(returning: components)
        print("[DeeplinkFetcher] Callback handled successfully for UUID: \(id)")
        return true
    }
}
