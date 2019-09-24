import Foundation
import CryptoStarterPack

public struct Radix256: Codable {
    private let rawPrefix: [Symbol]!
    private let rawValue: [Symbol]!
    private let rawChildren: [Symbol: Child]!
}

extension Radix256: RGArtifact {
    public typealias CryptoDelegateType = BaseCrypto
}

extension Radix256: Radix {
    public typealias Child = Stem256
    public typealias Symbol = String
    public typealias Digest = UInt256
    
    public var prefix: [Symbol] { return rawPrefix }
    public var value: [Symbol] { return rawValue }
    public var children: [Symbol : Child] { return rawChildren }
    
    public init(prefix: [Symbol], value: [Symbol], children: [Symbol : Child]) {
        self.rawPrefix = prefix
        self.rawValue = value
        self.rawChildren = children
    }
}
