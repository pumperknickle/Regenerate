import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public struct RGDictionary256<Key: Stringable, Value: CID>: Codable where Value.Digest == UInt256 {
	private let rawCore: CoreType!
	private let rawIncompleteChildren: Set<String>?
	private let rawChildren: Mapping<String, Value>?
	private let rawTargets: TrieSet<Edge>?
	private let rawMasks: TrieSet<Edge>?
	private let rawIsMasked: Singleton?
	
	public init(core: CoreType, incompleteChildren: Set<String>, children: Mapping<String, Value>, targets: TrieSet<String>, masks: TrieSet<String>, isMasked: Bool) {
		rawCore = core
		rawIncompleteChildren = incompleteChildren.isEmpty ? nil : incompleteChildren
		rawChildren = children.isEmpty() ? nil : children
		rawTargets = targets.isEmpty() ? nil : targets
		rawMasks = masks.isEmpty() ? nil : masks
		rawIsMasked = isMasked ? .void : nil
	}
}

extension RGDictionary256: RGDictionary {
	public typealias CoreType = RGRT256<Key, Value>

	public var core: CoreType! { return rawCore }
	public var incompleteChildren: Set<String>! { return rawIncompleteChildren ?? Set<String>([]) }
	public var children: Mapping<String, Value>! { return rawChildren ?? Mapping<String, Value>() }
	public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
	public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
	public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
}
