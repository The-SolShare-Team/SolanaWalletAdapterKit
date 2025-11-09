import Foundation

// public func generateNonce(bytes count: Int = 24) -> Data {
//     var data = Data(count: count)
//     let result = data.withUnsafeMutableBytes { ptr -> Int32 in
//         guard let base = ptr.baseAddress else { return -1 }
//         return SecRandomCopyBytes(kSecRandomDefault, count, base)
//     }
//     precondition(result == errSecSuccess, "Failed to generate secure random bytes")
//     return data
// }

func generateNonce(bytes count: Int = 24) throws -> Data {
    var data = Data(count: count)
    let status = data.withUnsafeMutableBytes { ptr -> OSStatus in
        SecRandomCopyBytes(kSecRandomDefault, count, ptr.baseAddress!)  // TODO: Is force unwrap safe here?
    }
    guard status == errSecSuccess else {
        throw OSStatusError(status: status)  // TODO: Is this the best way to handle the error?
    }
    return data
}

struct OSStatusError: Error {
    let status: OSStatus
}
