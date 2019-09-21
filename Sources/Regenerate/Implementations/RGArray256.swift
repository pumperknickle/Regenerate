import Foundation
import CryptoStarterPack

public struct RGArray256<Element: CID>: Codable where Element.Digest == UInt256 {
    private let rawCore: RGRT256<UInt256, UInt256>!
    private let rawLength: UInt256!
    private let rawMapping: [UInt256: Element]!
    private let rawCompleteChildren: Set<UInt256>!
}

extension RGArray256: RGArtifact {
    public typealias Digest = UInt256
}

extension RGArray256: RGArray {
    public typealias Index = UInt256
    public typealias Element = Element
    public typealias CoreType = RGRT256<UInt256, UInt256>
    
    public var core: RGRT256<UInt256, UInt256>! { return rawCore }
    public var length: UInt256! { return rawLength }
    public var mapping: [UInt256 : Element]! { return rawMapping }
    public var completeChildren: Set<UInt256>! { return rawCompleteChildren }
    
    public init(core: RGRT256<UInt256, UInt256>, length: UInt256, mapping: [UInt256 : Element], complete: Set<UInt256>) {
        self.rawCore = core
        self.rawLength = length
        self.rawMapping = mapping
        self.rawCompleteChildren = complete
    }
}
