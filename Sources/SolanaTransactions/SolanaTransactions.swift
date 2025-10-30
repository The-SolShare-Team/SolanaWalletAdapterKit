import ByteBuffer

public typealias Signature = [UInt8]
extension Signature {
    static public let length = 64
}

public typealias SolanaPublicKey = [UInt8]
public typealias Blockhash = [UInt8]

public enum VersionedMessage {
    case legacyMessage(LegacyMessage)
    case v0(V0Message)
}

public struct LegacyMessage {
    let signatureCount: UInt8
    let readOnlyAccounts: UInt8
    let readOnlyNonSigners: UInt8
    let accounts: [SolanaPublicKey]
    let blockhash: Blockhash
    let instructions: [CompiledInstruction]
}

public struct V0Message {
    let signatureCount: UInt8
    let readOnlyAccounts: UInt8
    let readOnlyNonSigners: UInt8
    let accounts: [SolanaPublicKey]
    let blockhash: Blockhash
    let instructions: [CompiledInstruction]
    let addressTableLookups: [AddressTableLookup]
}

public struct Transaction {
    let signatures: [Signature]
    let message: VersionedMessage
}

public struct CompiledInstruction {
    let programIdIndex: [UInt8]
    let accounts: [UInt8]
    let data: [UInt8]
}

public struct AddressTableLookup {
    let account: SolanaPublicKey
    let writableIndexes: [UInt8]
    let readOnlyIndexes: [UInt8]
}

func decodeShortUInt16(buffer: inout ByteBuffer) -> UInt16? {
    let mask7: UInt8 = 0x7F  // 0111 1111, mask lower 7 bits
    let contBit: UInt8 = 0x80  // 1000 0000, continuation flag
    let thirdByteMax: UInt8 = 0x03  // max value allowed in third byte

    guard let firstByte: UInt8 = buffer.readInteger() else { return nil }
    if firstByte < contBit {
        // Single-byte value
        return UInt16(firstByte)
    }

    guard let secondByte: UInt8 = buffer.readInteger() else { return nil }
    if secondByte < contBit {
        // Two-byte value: combine first and second
        let low7 = UInt16(firstByte & mask7)
        let high7 = UInt16(secondByte) << 7
        return low7 + high7
    }

    guard let thirdByte: UInt8 = buffer.readInteger() else { return nil }
    if thirdByte <= thirdByteMax {
        // Three-byte value: combine all three bytes
        let low7 = UInt16(firstByte & mask7)
        let mid7 = UInt16(secondByte & mask7) << 7
        let high2 = UInt16(thirdByte) << 14
        return low7 + mid7 + high2
    }

    // Invalid encoding
    return nil
}

func encodeShortUInt16(_ value: UInt16, buffer: inout ByteBuffer) {
    let mask7: UInt16 = 0x7F  // 0111 1111, mask lower 7 bits
    let contBit: UInt16 = 0x80  // 1000 0000, continuation flag

    if value < 128 {
        // Single-byte value
        buffer.writeInteger(UInt8(value))
    } else if value < 256 {
        // Two-byte value
        let firstByte = UInt8((value & mask7) | contBit)  // lower 7 bits + continuation
        let secondByte = UInt8(value >> 7)  // upper 7 bits
        buffer.writeInteger(firstByte)
        buffer.writeInteger(secondByte)
    } else {
        // Three-byte value
        let firstByte = UInt8((value & mask7) | contBit)  // lower 7 bits + continuation
        let secondByte = UInt8(((value >> 7) & mask7) | contBit)  // middle 7 bits + continuation
        let thirdByte = UInt8(value >> 14)  // upper 2 bits
        buffer.writeInteger(firstByte)
        buffer.writeInteger(secondByte)
        buffer.writeInteger(thirdByte)
    }
}

func decodeTransaction(buffer: inout ByteBuffer) -> Transaction {
    let signatureCount = Int(decodeShortUInt16(buffer: &buffer)!)
    let signatures = [Signature](unsafeUninitializedCapacity: signatureCount) {
        array, initializedCount in
        for i in 0..<signatureCount {
            array[i] = buffer.readBytes(length: Signature.length)!
        }
        initializedCount = signatureCount
    }
    decodeMessage(buffer: &buffer)
    return Transaction(
        signatures: signatures,
        message: .v0(
            V0Message(
                signatureCount: 0, readOnlyAccounts: 0, readOnlyNonSigners: 0, accounts: [],
                blockhash: [], instructions: [], addressTableLookups: [])))
}

func decodeMessage(buffer: inout ByteBuffer) {
    // If the first bit is set, the remaining bits
    // in the first byte will encode a version number. If the first bit is not
    // set, the first byte will be treated as the first byte of an encoded
    // legacy message.
    let mask7: UInt8 = 0x7F  // 0111 1111, mask lower 7 bits
    let firstBit: UInt8 = 0x80  // 1000 0000, continuation flag
    let firstByte: UInt8 = buffer.readInteger()!
    guard let version = firstByte & firstBit == 0 ? nil : firstByte & mask7 else {
        // Decode legacy message
        return
    }

    switch version {
    case 0:
        do {
            // Decode v0 message
            return
        }
    default:
        do {
            // Throw unsupported version
            return
        }
    }
}
