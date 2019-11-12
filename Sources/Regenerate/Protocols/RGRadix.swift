import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGRadix: RGArtifact where Child.Artifact == Self {
    associatedtype Child: RGRadixAddress

    var prefix: [Edge] { get }
    var value: [Edge] { get }
    var children: Mapping<Edge, Child> { get }
    
    init(prefix: [Edge], value: [Edge], children: Mapping<Edge, Child>)
}

public extension RGRadix {
	func encrypt(allKeys: CoveredTrie<String, [Bool]>, commonIv: [Bool]) -> Self? {
		let newChildren = children.elements().reduce(children) { (result, entry) -> Mapping<Edge, Child>? in
			guard let result = result else { return nil }
            guard let newChild = entry.1.encrypt(allKeys: allKeys.subtreeWithCover(keys: [entry.0]), commonIv: commonIv + entry.0.toBoolArray(), keyRoot: allKeys.contains(key: entry.0)) else { return nil }
			return result.setting(key: entry.0, value: newChild)
		}
		guard let finalChildren = newChildren else { return nil }
		return changing(children: finalChildren)
	}
	
    init() { self.init(prefix: [], value: [], children: Mapping<Edge, Child>()) }
	
	func set(property: String, to child: CryptoBindable) -> Self? {
		return nil
	}
	
	func get(property: String) -> CryptoBindable? {
		return nil
	}
	
	func value(for route: Path) -> [Edge]? {
		guard let firstLeg = route.first else { return value }
		guard let child = children[firstLeg] else { return nil }
		return child.value(for: Array(route.dropFirst()))
	}
	
	func key(for route: Path, prefix: [Edge]) -> [Edge]? {
		guard let firstLeg = route.first else { return prefix + self.prefix }
		guard let child = children[firstLeg] else { return nil }
		return child.key(for: Array(route.dropFirst()), prefix: prefix + self.prefix)
	}
	
	func properties() -> [String] {
		return []
	}
    
    func isValid() -> Bool {
        return !children.values().contains(where: { !$0.computedValidity() })
    }
    
    func isComplete() -> Bool {
        return !children.values().contains(where: { !$0.complete })
    }
    
    func changing(prefix: [Edge]? = nil, value: [Edge]? = nil, children: Mapping<Edge, Child>? = nil) -> Self {
        return Self(prefix: prefix == nil ? self.prefix : prefix!, value: value == nil ? self.value : value!, children: children == nil ? self.children : children!)
    }
    
    func values() -> [[Edge]] {
        return children.values().map { $0.values() }.reduce([], +) + (value.isEmpty ? [] : [value])
    }
    
    func keys() -> [[Edge]] {
        return children.values().map { $0.keys().map { prefix + $0 } }.reduce([], +) + (value.isEmpty ? [] : [prefix])
    }
    
    func pruning() -> Self {
        return changing(children: cuttingChildStems())
    }
    
    func cuttingChildStems() -> Mapping<Edge, Child> {
        return children.elements().reduce(Mapping<Edge, Child>(), { (result, entry) -> Mapping<Edge, Child> in
            return result.setting(key: entry.0, value: entry.1.empty())
        })
    }
    
    func cuttingGrandchildStems() -> Mapping<Edge, Child>? {
        return children.elements().reduce(Mapping<Edge, Child>(), { (result, entry) -> Mapping<Edge, Child>? in
            guard let result = result else { return nil }
            guard let node = entry.1.artifact else { return nil }
            guard let newChild = Child(artifact: node.pruning(), symmetricKeyHash: entry.1.symmetricKeyHash) else { return nil }
            return result.setting(key: entry.0, value: newChild)
        })
    }
    
    func grandchildPruning() -> Self? {
        guard let prunedChildren = cuttingGrandchildStems() else { return nil }
        return changing(children: prunedChildren)
    }
    
    func get(key: [Edge]) -> [Edge]? {
        if !key.starts(with: prefix) { return [] }
        let suffix = key - prefix
        guard let firstSymbol = suffix.first else { return value }
        guard let childStem = children[firstSymbol] else { return [] }
        return childStem.get(key: suffix)
    }
    
	func setting(key: [Edge], to value: [Edge]) -> Self? {
        if !key.starts(with: prefix) {
            if prefix.starts(with: key) {
                let childSuffix = prefix - key
                guard let firstChild = childSuffix.first else { return nil }
                guard let newChild = Child(artifact: changing(prefix: childSuffix), symmetricKeyHash: nil) else { return nil }
                return Self(prefix: key, value: value, children: Mapping<Edge, Child>().setting(key: firstChild, value: newChild))
            }
            let sharedPrefix = prefix ~> key
            let keySuffix = key - sharedPrefix
            let nodeSuffix = prefix - sharedPrefix
            guard let firstKeySuffix = keySuffix.first else { return nil }
            guard let firstNodeSuffix = nodeSuffix.first else { return nil }
			guard let keyChild = Child(artifact: Self(prefix: keySuffix, value: value, children: Mapping<Edge, Child>()), symmetricKeyHash: nil) else { return nil }
            guard let nodeChild = Child(artifact: changing(prefix: nodeSuffix), symmetricKeyHash: nil) else { return nil }
            let newChildren = Mapping<Edge, Child>().setting(key: firstKeySuffix, value: keyChild).setting(key: firstNodeSuffix, value: nodeChild)
            return Self(prefix: sharedPrefix, value: [], children: newChildren)
        }
        let suffix = key - prefix
        guard let firstSymbol = suffix.first else { return changing(value: value) }
        guard let firstStem = children[firstSymbol] else {
            guard let newStem = Child(artifact: Self(prefix: suffix, value: value, children: Mapping<Edge, Child>()), symmetricKeyHash: nil) else { return nil }
            return changing(children: children.setting(key: firstSymbol, value: newStem))
        }
        guard let newStem = firstStem.setting(key: suffix, to: value) else { return nil }
        return changing(children: children.setting(key: firstSymbol, value: newStem))
    }
    
    func deleting(key: [Edge]) -> Self? {
        if !key.starts(with: prefix) { return nil }
        let suffix = key - prefix
        guard let firstSymbol = suffix.first else {
            if value.isEmpty { return nil }
            let childValues = children.values()
            if childValues.count > 1 { return changing(value: []) }
            guard let childResult = childValues.first else { return nil }
            guard let childResultNode = childResult.artifact else { return nil }
            return childResultNode.changing(prefix: prefix + childResultNode.prefix)
        }
        guard let childStem = children[firstSymbol] else { return nil }
        guard let result = childStem.setting(key: suffix, to: []) else {
            let newChildren = children.deleting(key: firstSymbol)
            let newChildrenTuples = newChildren.elements()
            if !value.isEmpty || newChildrenTuples.count > 1 { return changing(children: newChildren) }
            if value.isEmpty && newChildren.isEmpty() { return Self() }
            guard let childTuple = newChildrenTuples.first else { return nil }
            guard let siblingNode = childTuple.1.artifact else { return nil }
            if prefix.isEmpty { return changing(children: newChildren) }
            return siblingNode.changing(prefix: prefix + siblingNode.prefix)
        }
        return changing(children: children.setting(key: firstSymbol, value: result))
    }
    
    func transitionProof(proofType: TransitionProofType, key: [Edge]) -> Self? {
        if !key.starts(with: prefix) {
            if proofType == .mutation || proofType == .deletion { return nil }
            return pruning()
        }
        let suffix = key - prefix
        guard let firstSymbol = suffix.first else {
            if value.isEmpty {
                if proofType != .creation { return nil }
                return pruning()
            }
            if proofType == .creation { return nil }
            if proofType == .mutation { return pruning() }
            return grandchildPruning()
        }
        guard let child = children[firstSymbol] else { return proofType == .creation ? pruning() : nil }
        guard let childTransitionProof = child.transitionProof(proofType: proofType, key: suffix) else { return nil }
        if proofType == .deletion {
            guard let children = cuttingGrandchildStems() else { return nil }
            return changing(children: children.setting(key: firstSymbol, value: childTransitionProof))
        }
        return changing(children: cuttingChildStems().setting(key: firstSymbol, value: childTransitionProof))
    }
    
    func merging(right: Self) -> Self {
        let newChildren = children.keys().reduce(Mapping<Edge, Child>()) { (result, entry) -> Mapping<Edge, Child> in
            let mergedChildStem = self.children[entry]!.merging(right: right.children[entry]!)
            return result.setting(key: entry, value: mergedChildStem)
        }
        return changing(children: newChildren)
    }
    
	func capture(digestString: String, content: [Bool], at route: Path, prefix: Path, previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> (Self, Mapping<String, [Path]>)? {
        guard let firstLeg = route.first else { return nil }
        guard let childStem = children[firstLeg] else { return nil }
        guard let childStemResult = childStem.capture(digestString: digestString, content: content, at: Array(route.dropFirst()), prefix: prefix + [firstLeg], previousKey: previousKey, keys: keys) else { return nil }
        let modifiedNode = changing(children: children.setting(key: firstLeg, value: childStemResult.0))
        return (modifiedNode, childStemResult.1)
    }
    
	func missing(prefix: Path) -> Mapping<String, [Path]> {
        if children.isEmpty() { return Mapping<String, [Path]>() }
		return children.elements().map { $0.1.missing(prefix: prefix + [$0.0]) }.reduce(Mapping<String, [Path]>(), +)
    }
    
	func contents(previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> Mapping<String, [Bool]> {
        return children.values().reduce(Mapping<String, [Bool]>(), { (result, entry) -> Mapping<String, [Bool]> in
			return result.overwrite(with: entry.contents(previousKey: previousKey, keys: keys))
        })
    }
	
	func targeting(_ targets: TrieSet<Edge>, prefix: Path) -> (Self, Mapping<String, [Path]>) {
		let reducedTargets = targets.subtree(keys: self.prefix)
		let childrenResult = children.elements().reduce((Mapping<Edge, Child>(), Mapping<String, [Path]>())) { (result, entry) -> (Mapping<Edge, Child>, Mapping<String, [Path]>) in
			let childResult = entry.1.targeting(reducedTargets.including(keys: [entry.0]), prefix: prefix + [entry.0])
			return (result.0.setting(key: entry.0, value: childResult.0), result.1 + childResult.1)
		}
		return (changing(children: childrenResult.0), childrenResult.1)
	}
	
	func masking(_ masks: TrieSet<Edge>, prefix: Path) -> (Self, Mapping<String, [Path]>) {
		let reducedMasks = masks.subtree(keys: self.prefix)
		let childrenResult = children.elements().reduce((Mapping<Edge, Child>(), Mapping<String, [Path]>())) { (result, entry) -> (Mapping<Edge, Child>, Mapping<String, [Path]>) in
			let childResult = entry.1.masking(reducedMasks.including(keys: [entry.0]), prefix: prefix + [entry.0])
			return (result.0.setting(key: entry.0, value: childResult.0), result.1 + childResult.1)
		}
		return (changing(children: childrenResult.0), childrenResult.1)
	}
	
	func mask(prefix: [Edge]) -> (Self, Mapping<String, [Path]>) {
		let childrenResult = children.elements().reduce((Mapping<Edge, Child>(), Mapping<String, [Path]>())) { (result, entry) -> (Mapping<Edge, Child>, Mapping<String, [Path]>) in
			let childResult = entry.1.mask(prefix: prefix + [entry.0])
			return (result.0.setting(key: entry.0, value: childResult.0), result.1 + childResult.1)
		}
		return (changing(children: childrenResult.0), childrenResult.1)
	}
	
	func shouldMask(_ masks: TrieSet<Edge>, prefix: [Edge]) -> Bool {
		return masks.contains(self.prefix)
	}
}
