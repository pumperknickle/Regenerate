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
    func changing(core: CoreType? = nil, incompleteChildren: Set<String>? = nil, children: Mapping<String, Value>? = nil, targets: TrieSet<String>? = nil, masks: TrieSet<String>? = nil, isMasked: Bool? = nil, length: Index? = nil) -> Self {
        return Self(core: core ?? self.core, incompleteChildren: incompleteChildren ?? self.incompleteChildren, children: children ?? self.children, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked, length: length ?? self.length)
	}

	init(core: CoreType, incompleteChildren: Set<String>, children: Mapping<String, Value>, targets: TrieSet<String>, masks: TrieSet<String>, isMasked: Bool) {
		self.init(core: core, incompleteChildren: incompleteChildren, children: children, targets: targets, masks: masks, isMasked: isMasked, length: Index(children.keys().count))
	}

	init?(_ rawArray: [Element]) {
		let rawMapping = rawArray.reduce((Mapping<Index, Element>(), Index(0))) { (result, entry) -> (Mapping<Index, Element>, Index) in
            return (result.0.setting(key: result.1, value: entry.empty()), result.1.advanced(by: 1))
		}
        let newChildren = rawArray.reduce((Mapping<String, Element>(), Index(0))) { (result, entry) -> (Mapping<String, Element>, Index) in
            return (result.0.setting(key: result.1.toString(), value: entry), result.1.advanced(by: 1))
        }
        guard let core = CoreType(raw: rawMapping.0.elements()) else { return nil }
        self.init(core: core, incompleteChildren: Set<String>([]), children: newChildren.0, targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: false, length: rawMapping.1)
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
