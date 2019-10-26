import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public struct RGArray256<Element: CID>: Codable where Element.Digest == UInt256 {
	private let rawCore: CoreType!
	private let rawIncompleteChildren: Set<Key>?
	private let rawChildren: Mapping<Key, Value>?
	private let rawTargets: TrieSet<Edge>?
	private let rawMasks: TrieSet<Edge>?
	private let rawIsMasked: Singleton?
	private let rawLength: Digest!
	
	public init(core: CoreType, incompleteChildren: Set<Key>, children: Mapping<Key, Value>, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool, length: Digest) {
		rawCore = core
		rawIncompleteChildren = incompleteChildren.isEmpty ? nil : incompleteChildren
		rawChildren = children.isEmpty() ? nil : children
		rawTargets = targets.isEmpty() ? nil : targets
		rawMasks = masks.isEmpty() ? nil : masks
		rawIsMasked = isMasked ? .void : nil
		rawLength = length
	}
}

extension RGArray256: RGArtifact {
	public typealias Digest = UInt256
}

extension RGArray256: RGArray {
	public typealias Key = Digest
	public typealias Value = Element
	public typealias CoreType = RGRT256<Key, Value>

	public var core: CoreType! { return rawCore }
	public var incompleteChildren: Set<Key>! { return rawIncompleteChildren ?? Set<Key>([]) }
	public var children: Mapping<Key, Value>! { return rawChildren ?? Mapping<Key, Value>() }
	public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
	public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
	public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
	public var length: Digest! { return rawLength }
}
