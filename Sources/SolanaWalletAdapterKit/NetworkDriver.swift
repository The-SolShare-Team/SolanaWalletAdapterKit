import SolanaKit

class NetworkDriver: RpccoreHttpNetworkDriver {
    func makeHttpRequest(request: RpccoreHttpRequest, completionHandler: @escaping @Sendable (String?, (any Error)?) -> Void) {
        print("**********************************")
        print("\nBody:       ", request.body)
        print("\nMethod:     ", request.method)
        print("\nProperties: ", request.properties)
        print("\nURL:        ", request.url)
        print("**********************************")
    }
}
