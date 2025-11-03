import Foundation

public class BackpackWallet: BaseDeeplinkWallet {
    public override var baseURL: URL {
        URL(string: "https://backpack.app/ul/v1")!
    }
}
