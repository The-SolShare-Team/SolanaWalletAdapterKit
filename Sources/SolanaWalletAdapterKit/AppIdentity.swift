import Foundation

public struct AppIdentity: Sendable {
    let name: String
    let url: URL
    let icon: String

    public init(name: String, url: URL, icon: String) {
        self.name = name
        self.url = url
        self.icon = icon
    }
}
