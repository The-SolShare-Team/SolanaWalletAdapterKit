import Collections
import Foundation
import SwiftBorsh

public protocol Instruction {
    var programId: PublicKey { get }
    var accounts: [AccountMeta] { get }
    var data: BorshEncodable { get }
}

public struct AccountMeta {
    public let publicKey: PublicKey
    public let isSigner: Bool
    public let isWritable: Bool

    public init(publicKey: PublicKey, isSigner: Bool, isWritable: Bool) {
        self.publicKey = publicKey
        self.isSigner = isSigner
        self.isWritable = isWritable
    }
}

@resultBuilder
public enum InstructionsBuilder {
    public static func buildExpression(_ instruction: Instruction) -> [Instruction] {
        [instruction]
    }

    public static func buildBlock(_ instructions: [Instruction]...) -> [Instruction] {
        instructions.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Instruction]?) -> [Instruction] {
        component ?? []
    }

    public static func buildEither(first component: [Instruction]) -> [Instruction] {
        component
    }

    public static func buildEither(second component: [Instruction]) -> [Instruction] {
        component
    }

    public static func buildArray(_ components: [[Instruction]]) -> [Instruction] {
        components.flatMap { $0 }
    }
}

extension Transaction {
    public init(
        blockhash: Blockhash, @InstructionsBuilder _ instructionsBuilder: () -> [Instruction]
    ) throws {
        let instructions = instructionsBuilder()

        var writableSigners: OrderedSet<PublicKey> = []
        var readOnlySigners: OrderedSet<PublicKey> = []
        var readOnlyNonSigners: OrderedSet<PublicKey> = []
        var accounts: OrderedSet<PublicKey> = []

        for instruction in instructions {
            for account in instruction.accounts {
                switch (account.isSigner, account.isWritable) {
                case (true, true): writableSigners.append(account.publicKey)
                case (true, false): readOnlySigners.append(account.publicKey)
                case (false, true): break
                case (false, false): readOnlyNonSigners.append(account.publicKey)
                }
                accounts.append(account.publicKey)
            }
            accounts.append(instruction.programId)  // ProgramID needs to be at the end of the accounts array (otherwise, the transaction is invalid)
        }

        let signers = writableSigners.union(readOnlySigners)

        let compiledInstructions = try instructions.map {
            CompiledInstruction(
                programIdIndex: UInt8(accounts.firstIndex(of: $0.programId)!),
                accounts: $0.accounts.map { UInt8(accounts.firstIndex(of: $0.publicKey)!) },
                data: try BorshEncoder.encode($0.data))
        }

        signatures = signers.map { _ in
            "1111111111111111111111111111111111111111111111111111111111111111"  // 64-byte placeholder array for signatures (otherwise, the transaction is invalid)
        }
        message = .legacyMessage(
            LegacyMessage(
                signatureCount: UInt8(signers.count),
                readOnlyAccounts: UInt8(readOnlySigners.count),
                readOnlyNonSigners: UInt8(readOnlyNonSigners.count),
                accounts: Array(accounts), blockhash: blockhash, instructions: compiledInstructions
            ))
    }
}
