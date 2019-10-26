import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public struct RGDictionary256<Key: Stringable, Value: CID>: Codable where Value.Digest == UInt256 {
	private let rawCore: CoreType!
	private let rawIncompleteChildren: Set<Key>?
	private let rawChildren: Mapping<Key, Value>?
	private let rawTargets: TrieSet<Edge>?
	private let rawMasks: TrieSet<Edge>?
	private let rawIsMasked: Singleton?
	
	public init(core: RGRT256<Key, Value>, incompleteChildren: Set<Key>, children: Mapping<Key, Value>, targets: TrieSet<String>, masks: TrieSet<String>, isMasked: Bool) {
		rawCore = core
		rawIncompleteChildren = incompleteChildren.isEmpty ? nil : incompleteChildren
		rawChildren = children.isEmpty() ? nil : children
		rawTargets = targets.isEmpty() ? nil : targets
		rawMasks = masks.isEmpty() ? nil : masks
		rawIsMasked = isMasked ? .void : nil
	}
}

extension RGDictionary256: RGArtifact {	
	public typealias Digest = UInt256
}

extension RGDictionary256: RGDictionary {
	public typealias CoreType = RGRT256<Key, Value>

	public var core: CoreType! { return rawCore }
	public var incompleteChildren: Set<Key>! { return rawIncompleteChildren ?? Set<Key>([]) }
	public var children: Mapping<Key, Value>! { return rawChildren ?? Mapping<Key, Value>() }
	public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
	public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
	public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
}
