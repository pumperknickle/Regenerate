import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGArray: RGDictionary where Key: FixedWidthInteger {
	typealias Index = Key
	typealias Element = Value
	
	var length: Index! { get }
	
	init(core: CoreType, incompleteChildren: Set<Index>, children: Mapping<Index, Element>, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool, length: Index)
}

public extension RGArray {
	func changing(core: CoreType? = nil, incompleteChildren: Set<Key>? = nil, children: Mapping<Key, Value>? = nil, targets: TrieSet<String>? = nil, masks: TrieSet<String>? = nil, isMasked: Bool? = nil) -> Self {
		return Self(core: core ?? self.core, incompleteChildren: incompleteChildren ?? self.incompleteChildren, children: children ?? self.children, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked, length: length)
	}
	
	init(core: CoreType, incompleteChildren: Set<Key>, children: Mapping<Key, Value>, targets: TrieSet<String>, masks: TrieSet<String>, isMasked: Bool) {
		self.init(core: core, incompleteChildren: incompleteChildren, children: children, targets: targets, masks: masks, isMasked: isMasked, length: Index(children.keys().count))
	}
	
	
	init?(_ rawArray: [Element]) {
		let rawMapping = rawArray.reduce((Mapping<Index, Element>(), Index(0))) { (result, entry) -> (Mapping<Index, Element>, Index)? in
			guard let result = result else { return nil }
			return (result.0.setting(key: result.1, value: entry), result.1.advanced(by: 1))
		}
		guard let mappingResult = rawMapping else { return nil }
		guard let core = CoreType(raw: mappingResult.0.elements()) else { return nil }
		self.init(core: core, incompleteChildren: Set<Index>([]), children: mappingResult.0, targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: false, length: mappingResult.1)
	}
}
