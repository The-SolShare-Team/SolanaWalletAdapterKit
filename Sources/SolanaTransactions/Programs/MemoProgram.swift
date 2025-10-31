import SwiftBorsh

public enum MemoProgram: Program, Instruction {
    public static let programId: PublicKey = "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr"

    case publishMemo(account: PublicKey, memo: String)

    public var accounts: [AccountMeta] {
        return switch self {
        case .publishMemo(let account, _):
            [
                AccountMeta(publicKey: account, isSigner: true, isWritable: true)
            ]
        }
    }

    public var data: BorshEncodable {
        switch self {
        case .publishMemo(_, let memo): memo
        }
    }
}
