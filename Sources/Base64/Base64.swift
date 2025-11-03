import Foundation

public enum Base64 {
    public static func encode(_ input: [UInt8]) -> String {
        Data(input).base64EncodedString()
    }

    public static func decode(_ input: String) -> [UInt8]? {
        guard let data = Data(base64Encoded: input) else {
            return nil
        }

        return Array(data)
    }
}
