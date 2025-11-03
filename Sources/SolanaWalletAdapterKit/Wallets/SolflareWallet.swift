import Foundation

public class SolflareWallet: BaseDeeplinkWallet {
    public override var baseURL: URL {
        URL(string: "https://solflare.com/ul/v1")!
    }
}
