import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGArray: RGDictionary where Key: FixedWidthInteger {
	typealias Index = Key
	typealias Element = Value
    typealias Artifact = Element.Artifact

	var length: Index! { get }

	init(core: CoreType, incompleteChildren: Set<String>, children: Mapping<String, Element>, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool, length: Index)
}

public extension RGArray {
	func changing(core: CoreType? = nil, incompleteChildren: Set<String>? = nil, children: Mapping<String, Value>? = nil, targets: TrieSet<String>? = nil, masks: TrieSet<String>? = nil, isMasked: Bool? = nil) -> Self {
		return Self(core: core ?? self.core, incompleteChildren: incompleteChildren ?? self.incompleteChildren, children: children ?? self.children, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked, length: length)
	}

	init(core: CoreType, incompleteChildren: Set<String>, children: Mapping<String, Value>, targets: TrieSet<String>, masks: TrieSet<String>, isMasked: Bool) {
		self.init(core: core, incompleteChildren: incompleteChildren, children: children, targets: targets, masks: masks, isMasked: isMasked, length: Index(children.keys().count))
	}

	init?(_ rawArray: [Element]) {
		let rawMapping = rawArray.reduce((Mapping<Index, Element>(), Index(0))) { (result, entry) -> (Mapping<Index, Element>, Index)? in
			guard let result = result else { return nil }
			return (result.0.setting(key: result.1, value: entry), result.1.advanced(by: 1))
		}
		guard let mappingResult = rawMapping else { return nil }
		guard let core = CoreType(raw: mappingResult.0.elements()) else { return nil }
		let newChildren = mappingResult.0.elements().reduce(Mapping<String, Element>()) { (result, entry) -> Mapping<String, Element> in
			return result.setting(key: entry.0.toString(), value: entry.1)
		}
		self.init(core: core, incompleteChildren: Set<String>([]), children: newChildren, targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: false, length: mappingResult.1)
	}
    
    init?(artifacts: [Artifact?]) {
        guard let elements = artifacts.reduce([], { (result, entry) -> [Element]? in
            guard let result = result else { return nil }
            guard let entry = entry else { return nil }
            guard let element = Element(artifact: entry, complete: true) else { return nil }
            return result + [element]
        }) else { return nil }
        self.init(elements)
    }
}
