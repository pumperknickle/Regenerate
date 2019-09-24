import Foundation
import CryptoStarterPack

public struct Radix256: Codable {
    private let rawPrefix: [Edge]!
    private let rawValue: [Edge]!
    private let rawChildren: [Edge: Child]!
}

extension Radix256: RGArtifact {
    public typealias CryptoDelegateType = BaseCrypto
}

extension Radix256: Radix {
    public typealias Child = Stem256
    public typealias Edge = String
    public typealias Digest = UInt256
    
    public var prefix: [Edge] { return rawPrefix }
    public var value: [Edge] { return rawValue }
    public var children: [Edge : Child] { return rawChildren }
    
    public init(prefix: [Edge], value: [Edge], children: [Edge : Child]) {
        self.rawPrefix = prefix
        self.rawValue = value
        self.rawChildren = children
    }
}
