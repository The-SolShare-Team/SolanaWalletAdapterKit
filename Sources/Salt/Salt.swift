import Foundation
import TweetNacl

#if canImport(salkt)
    import salkt
    extension KotlinByteArray {
        convenience init(from data: Data) {
            self.init(size: Int32(data.count))
            data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
                let buffer = rawBufferPointer.bindMemory(to: Int8.self)
                for (index, byte) in buffer.enumerated() {
                    self.set(index: Int32(index), value: byte)
                }
            }
        }
    }
    extension SaltUtil {
        public static func isOnCurve(publicKey: Data) throws(NaclUtilError) -> Bool {
            guard publicKey.count == 32 else { throw .badPublicKeySize }
            return KotlinByteArray(from: publicKey).isOnCurve()
        }
    }
#else
    extension SaltUtil {
        public static func isOnCurve(publicKey: Data) throws(NaclUtilError) -> Bool {
            fatalError()
        }
    }
#endif

public typealias SaltBox = NaclBox
public typealias SaltSign = NaclSign
public typealias SaltSecretBox = NaclSecretBox
public typealias SaltScalarMult = NaclScalarMult
public typealias SaltUtil = NaclUtil
