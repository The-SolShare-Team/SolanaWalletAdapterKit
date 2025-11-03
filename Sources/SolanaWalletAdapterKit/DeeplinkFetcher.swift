import Foundation

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

enum DeeplinkFetchingError: Error {
    case timeout
    case unableToOpen
    case decodeError
}

public class DeeplinkFetcher {
    let scheme: String

    internal init(scheme: String) {
        self.scheme = scheme
    }

    @MainActor
    private var pendingRequests: [UUID: PendingRequest] = [:]

    private struct PendingRequest {
        let continuation: CheckedContinuation<Result<URLComponents, DeeplinkFetchingError>, Never>
        let timeoutTask: Task<Void, Never>
    }

    @available(iOS 16.0, macOS 13.0, *)
    func fetch(_ url: URL, callbackParameter: String, timeout: Duration)
        async throws(DeeplinkFetchingError) -> URLComponents
    {
        try await fetch(
            url, callbackParameter: callbackParameter,
            timeout: Double(timeout.components.seconds) + Double(timeout.components.attoseconds)
                / 1_000_000_000_000_000_000)
    }

    @MainActor
    func fetch(_ url: URL, callbackParameter: String, timeout: TimeInterval = 30.0)
        async throws(DeeplinkFetchingError) -> URLComponents
    {
        let id = UUID()
        let callbackURL = "\(scheme)\(id.uuidString)"

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
                    Task { // <-- wrap async call in Task
                        print("opening \(finalURL)")
                        let success = await UIApplication.shared.open(finalURL)
                        if !success {
                            continuation.resume(returning: .failure(.unableToOpen))
                        }
                    }
            #elseif os(macOS)
                let success = NSWorkspace.shared.open(finalURL)
                if !success {
                    continuation.resume(returning: .failure(.unableToOpen))
                }
            #endif

            
        }

        switch result {
        case .failure(let cause): throw cause
        case .success(let components): return components
        }
    }

    @MainActor
    func handleCallback(_ url: URL) -> Bool {
        guard url.scheme == scheme else { return false }
            print ("attmepting to handle \(url)")
            
            // ⭐️ FIX 1: Safely unwrap components ⭐️
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                // If the URL is bad, we can't process it. We should attempt to fail the request
                // if it still exists, but safely exit the function otherwise.
                return true
            }
            
            // Now look up the request
            if let id = UUID(uuidString: url.lastPathComponent),
               let request = pendingRequests.removeValue(forKey: id)
            {
                print("UUID:\(id), rqeuest: \(request)")
                request.timeoutTask.cancel()
                request.continuation.resume(returning: .success(components))
                
                // ⭐️ FIX 2: We must cancel the timeout task.
                // If the task has already run and removed the request, the request variable
                // would be nil, so the timeout logic handles the failure.
                // This is the correct logic for handling success/failure.
                return true
            }
            
            // If we reach here, the request wasn't found (likely timed out),
            // so we let the timeout task handle the failure.
            return true
    }
}
