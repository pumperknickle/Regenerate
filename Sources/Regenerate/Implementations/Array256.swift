import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public struct Array256<Element: Addressable>: Codable where Element.Digest == UInt256 {
	private let rawCore: CoreType!
	private let rawIncompleteChildren: Set<String>?
	private let rawChildren: Mapping<String, Value>?
	private let rawTargets: TrieSet<Edge>?
	private let rawMasks: TrieSet<Edge>?
	private let rawIsMasked: Singleton?
	private let rawLength: UInt256!

	public init(core: CoreType, incompleteChildren: Set<String>, children: Mapping<String, Value>, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool, length: UInt256) {
		rawCore = core
		rawIncompleteChildren = incompleteChildren.isEmpty ? nil : incompleteChildren
		rawChildren = children.isEmpty() ? nil : children
		rawTargets = targets.isEmpty() ? nil : targets
		rawMasks = masks.isEmpty() ? nil : masks
		rawIsMasked = isMasked ? .void : nil
		rawLength = length
	}
}

extension Array256: RGArray {
	public typealias Key = UInt256
	public typealias Value = Element
	public typealias CoreType = RT256<Key, Value>

	public var core: CoreType! { return rawCore }
	public var incompleteChildren: Set<String>! { return rawIncompleteChildren ?? Set<String>([]) }
	public var children: Mapping<String, Value>! { return rawChildren ?? Mapping<String, Value>() }
	public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
	public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
	public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
	public var length: UInt256! { return rawLength }
}
