import Foundation
import CryptoStarterPack

public struct Radix256: Codable {
    private let rawPrefix: [Bool]!
    private let rawValue: [Bool]!
    private let rawChildren: [Bool: Stem256]!
}

extension Radix256: RGArtifact {
    public typealias CryptoDelegateType = BaseCrypto
}

extension Radix256: Radix {
    public typealias Child = Stem256
    public typealias Symbol = Bool
    public typealias Digest = UInt256
    
    public var prefix: [Bool] { return rawPrefix }
    public var value: [Bool] { return rawValue }
    public var children: [Bool : Stem256] { return rawChildren }
    
    public init(prefix: [Bool], value: [Bool], children: [Bool : Stem256]) {
        self.rawPrefix = prefix
        self.rawValue = value
        self.rawChildren = children
    }
}
