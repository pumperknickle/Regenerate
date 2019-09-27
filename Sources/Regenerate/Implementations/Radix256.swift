import Foundation
import Bedrock
import CryptoStarterPack
import TMap

public struct Radix256: Codable {
    private let rawPrefix: [Edge]!
    private let rawValue: [Edge]!
    private let rawChildren: [TMap<Edge, Child>]!
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
    public var children: TMap<Edge, Child> { return rawChildren.first! }
    
    public init(prefix: [Edge], value: [Edge], children: TMap<Edge, Child>) {
        self.rawPrefix = prefix
        self.rawValue = value
        self.rawChildren = [children]
    }
}
