import SwiftBorsh

public protocol Instruction {
    var programId: PublicKey { get }
    var accounts: [AccountMeta] { get }
    var data: BorshEncodable { get }
}

public struct AccountMeta {
    let publicKey: PublicKey
    let isSigner: Bool
    let isWritable: Bool

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
        signatures = []

        var writableSigners: Set<PublicKey> = []
        var readOnlySigners: Set<PublicKey> = []
        var writableNonSigners: Set<PublicKey> = []
        var readOnlyNonSigners: Set<PublicKey> = []
        var programIds: Set<PublicKey> = []

        for instruction in instructions {
            for account in instruction.accounts {
                switch (account.isSigner, account.isWritable) {
                case (true, true): writableSigners.insert(account.publicKey)
                case (true, false): readOnlySigners.insert(account.publicKey)
                case (false, true): writableNonSigners.insert(account.publicKey)
                case (false, false): readOnlyNonSigners.insert(account.publicKey)
                }
            }
            programIds.insert(instruction.programId)
        }

        let signers = writableSigners.union(readOnlySigners)
        let accounts = Array(
            signers.union(writableNonSigners).union(readOnlyNonSigners).union(programIds))

        let compiledInstructions = try instructions.map {
            CompiledInstruction(
                programIdIndex: UInt8(accounts.firstIndex(of: $0.programId)!),
                accounts: $0.accounts.map { UInt8(accounts.firstIndex(of: $0.publicKey)!) },
                data: try BorshEncoder.encode($0.data))
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
