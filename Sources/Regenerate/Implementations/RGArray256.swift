//import Foundation
//import Bedrock
//import AwesomeDictionary
//import AwesomeTrie
//
//public struct RGArray256<Element: CID>: Codable where Element.Digest == UInt256 {
//	private let rawCore: CoreType!
//	private let rawLength: Index!
//	private let rawIncompleteChildren: Set<Index>?
//	private let rawChildren: Mapping<Index, Element>?
//	private let rawTargets: TrieSet<Edge>?
//	private let rawMasks: TrieSet<Edge>?
//	private let rawIsMasked: Singleton?
//	
//	public init(core: RGRT256<UInt256, UInt256>, length: UInt256, incompleteChildren: Set<UInt256>, children: Mapping<UInt256, Element>, targets: TrieSet<Self.Edge>, masks: TrieSet<Self.Edge>, isMasked: Bool) {
//		rawCore = core
//		rawLength = length
//		rawIncompleteChildren = incompleteChildren.isEmpty ? nil : incompleteChildren
//		rawChildren = children.isEmpty() ? nil : children
//		rawTargets = targets.isEmpty() ? nil : targets
//		rawMasks = masks.isEmpty() ? nil : masks
//		rawIsMasked = isMasked ? .void : nil
//	}
//}
//
//extension RGArray256: RGArtifact {
//	public typealias Digest = UInt256
//}
//
//extension RGArray256: RGArray {
//	public typealias Index = UInt256
//	public typealias Element = Element
//	public typealias CoreType = RGRT256<UInt256, UInt256>
//	
//	public var core: CoreType! { return rawCore }
//	public var length: Index! { return rawLength }
//	public var incompleteChildren: Set<Index>! { return rawIncompleteChildren ?? Set<Index>([]) }
//	public var children: Mapping<Index, Element>! { return rawChildren ?? Mapping<Index, Element>() }
//	public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
//	public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
//	public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
//}

//import Foundation
//import Bedrock
//import AwesomeDictionary
//
//public struct RGArray256<Element: CID>: Codable where Element.Digest == UInt256 {
//    private let rawCore: CoreType!
//    private let rawLength: Digest!
//    private let rawMapping: Mapping<Digest, Element>!
//    private let rawCompleteChildren: Set<Digest>!
//}
//
//extension RGArray256: RGArtifact {
//    public typealias Digest = UInt256
//}
//
//extension RGArray256: RGArray {
//    public typealias Index = UInt256
//    public typealias Element = Element
//    public typealias CoreType = RGRT256<UInt256, UInt256>
//    
//    public var core: CoreType! { return rawCore }
//    public var length: Digest! { return rawLength }
//    public var mapping: Mapping<Digest, Element>! { return rawMapping }
//    public var completeChildren: Set<Digest>! { return rawCompleteChildren }
//    
//    public init(core: CoreType, length: Digest, mapping: Mapping<Digest, Element>, complete: Set<Digest>) {
//        self.rawCore = core
//        self.rawLength = length
//        self.rawMapping = mapping
//        self.rawCompleteChildren = complete
//    }
//}
