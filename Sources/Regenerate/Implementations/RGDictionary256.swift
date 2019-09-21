import Foundation
import CryptoStarterPack

public struct RGDictionary256<Key: Stringable, Value: CID>: Codable where Value.Digest == UInt256 {
    private let rawCore: RGRT256<Key, UInt256>!
    private let rawMapping: [Key: Value]!
    private let rawIncompleteChildren: Set<Key>!
}

extension RGDictionary256: RGArtifact {
    public typealias Digest = UInt256
}

extension RGDictionary256: RGDictionary {
    public typealias Key = Key
    public typealias Value = Value
    public typealias CoreType = RGRT256<Key, Digest>
    
    public var core: RGRT256<Key, Digest>! { return rawCore }
    public var mapping: [Key : Value]! { return rawMapping }
    public var incompleteChildren: Set<Key>! { return rawIncompleteChildren }
    
    public init(core: RGRT256<Key, Digest>, mapping: [Key : Value], incomplete: Set<Key>) {
        self.rawCore = core
        self.rawMapping = mapping
        self.rawIncompleteChildren = incomplete
    }
}
