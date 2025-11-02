import Base58
import Foundation
import Testing

@testable import SolanaRPC

@Test func myTest() async {
    let client = SolanaRPCClient(endpoint: .devnet)
    print(try! await client.getVersion())
}
