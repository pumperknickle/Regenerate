import Foundation
import Bedrock

public struct ArrayOverlay256<Element: CID>: Codable where Element.Digest == UInt256 {
    private let rawCore: RTOverlay256<UInt256, UInt256>!
    private let rawLength: UInt256!
    private let rawMapping: [UInt256: Element]!
    private let rawCompleteChildren: Set<UInt256>!
}

extension ArrayOverlay256: RGArtifact {
    public typealias Digest = UInt256
}

extension ArrayOverlay256: RGArray {
    public typealias Index = UInt256
    public typealias Element = Element
    public typealias CoreType = RTOverlay256<UInt256, UInt256>
    
    public var core: CoreType! { return rawCore }
    public var length: Index! { return rawLength }
    public var mapping: [UInt256: Element]! { return rawMapping }
    public var completeChildren: Set<UInt256>! { return rawCompleteChildren }
    
    public init(core: CoreType, length: Index, mapping: [UInt256: Element], complete: Set<UInt256>) {
        self.rawCore = core
        self.rawLength = length
        self.rawMapping = mapping
        self.rawCompleteChildren = complete
    }
}

extension ArrayOverlay256: ArrayOverlay { }
