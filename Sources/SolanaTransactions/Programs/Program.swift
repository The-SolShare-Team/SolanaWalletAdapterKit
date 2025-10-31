public protocol Program {
    static var programId: PublicKey { get }
}

extension Program {
    public var programId: PublicKey {
        Self.programId
    }
}