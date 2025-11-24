import Collections
import Foundation
import SwiftBorsh
import Base58

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
        var writableNonSigners: OrderedSet<PublicKey> = []
        var readOnlyNonSigners: OrderedSet<PublicKey> = []
        var programIds: OrderedSet<PublicKey> = []

        for instruction in instructions {
            programIds.append(instruction.programId)
            for account in instruction.accounts {
                switch (account.isSigner, account.isWritable) {
                case (true, true): writableSigners.append(account.publicKey)
                case (true, false): readOnlySigners.append(account.publicKey)
                case (false, true): writableNonSigners.append(account.publicKey)
                case (false, false): readOnlyNonSigners.append(account.publicKey)
                }
            }
        }
        let orderedAccounts = [
            writableSigners.elements,
            readOnlySigners.elements,
            writableNonSigners.elements,
            readOnlyNonSigners.elements,
            programIds.elements
        ].flatMap { $0 }
        
        print("=== DEBUG: Transaction Message Builder ===")
        print("Final Ordered Accounts: \(try orderedAccounts.map { Base58.encode($0.bytes)})")
        print("Signature Count (Required Signers): \(writableSigners.union(readOnlySigners).count)")
        print("Read-only Signers Count: \(readOnlySigners.count)")
        print("Read-only Non-signers Count: \(readOnlyNonSigners.count)")
        print("========================================")

        let compiledInstructions = try instructions.map {
            CompiledInstruction(
                programIdIndex: UInt8(orderedAccounts.firstIndex(of: $0.programId)!),
                accounts: $0.accounts.map { UInt8(orderedAccounts.firstIndex(of: $0.publicKey)!) },
                data: try BorshEncoder.encode($0.data))
        }

        let signers = writableSigners.union(readOnlySigners)

        signatures = signers.map { _ in
            "1111111111111111111111111111111111111111111111111111111111111111"
        }
        message = .legacyMessage(
            LegacyMessage(
                signatureCount: UInt8(signers.count),
                readOnlyAccounts: UInt8(readOnlySigners.count),
                readOnlyNonSigners: UInt8(readOnlyNonSigners.count),
                accounts: orderedAccounts, blockhash: blockhash, instructions: compiledInstructions
            ))
    }
}
