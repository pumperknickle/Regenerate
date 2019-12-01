import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGDictionary: RGArtifact {
	associatedtype Key: Stringable
	associatedtype Value: Addressable
	associatedtype CoreType: RGRT where CoreType.Key == Key, CoreType.Value == Value
	typealias CoreRoot = CoreType.Root

	var core: CoreType! { get }
	var incompleteChildren: Set<String>! { get }
	var children: Mapping<String, Value>! { get }
	var targets: TrieSet<Edge>! { get }
	var masks: TrieSet<Edge>! { get }
	var isMasked: Bool! { get }

	init(core: CoreType, incompleteChildren: Set<String>, children: Mapping<String, Value>, targets: TrieSet<String>, masks: TrieSet<String>, isMasked: Bool)
	func changing(core: CoreType?, incompleteChildren: Set<String>?, children: Mapping<String, Value>?, targets: TrieSet<String>?, masks: TrieSet<String>?, isMasked: Bool?) -> Self
}

public extension RGDictionary {
	func encrypt(allKeys: CoveredTrie<String, [Bool]>, commonIv: [Bool]) -> Self? {
		let encryptedChildren = children.elements().reduce(Mapping<String, Value>()) { (result, entry) -> Mapping<String, Value>? in
			guard let result = result else { return nil }
            guard let childResult = entry.1.encrypt(allKeys: allKeys.subtreeWithCover(keys: [entry.0]), commonIv: commonIv + entry.0.toBoolArray(), keyRoot: allKeys.contains(key: entry.0)) else { return nil }
			return result.setting(key: entry.0, value: childResult)
		}
		guard let unwrappedChildren = encryptedChildren else { return nil }
		let convertedChildren = unwrappedChildren.elements().reduce(Mapping<Key, Value>()) { (result, entry) -> Mapping<Key, Value>? in
			guard let result = result else { return nil }
			guard let key = Key(stringValue: entry.0) else { return nil }
			return result.setting(key: key, value: entry.1)
		}
		guard let finalConvertedChildren = convertedChildren else { return nil }
		guard let newCore = CoreType(raw: finalConvertedChildren.elements()) else { return nil }
		guard let cover = allKeys.cover else { return changing(core: newCore, children: unwrappedChildren) }
		guard let encryptedCore = newCore.encrypt(allKeys: CoveredTrie<String, [Bool]>(trie: TrieMapping<String, [Bool]>(), cover: cover), commonIv: commonIv + commonIv) else { return nil }
		return changing(core: encryptedCore, children: unwrappedChildren)
	}

	init?(_ mapping: Mapping<Key, Value>) {
		let coreTuples = mapping.elements()
		let children = coreTuples.reduce(Mapping<String, Value>()) { (result, entry) -> Mapping<String, Value> in
			return result.setting(key: entry.0.toString(), value: entry.1)
		}
		guard let core = CoreType(raw: coreTuples) else { return nil }
		self.init(core: core, incompleteChildren: Set([]), children: children, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: false)
	}

	func set(property: String, to child: CryptoBindable) -> Self? {
		return nil
	}

	func get(property: String) -> CryptoBindable? {
		return nil
	}

	func properties() -> [String] {
		return []
	}

	func isComplete() -> Bool {
		return core.complete() && !children.values().contains(where: { !$0.complete })
	}

	func pruning() -> Self {
		return Self(core: CoreType(root: core.root.empty()), incompleteChildren: Set<String>(), children: Mapping<String, Value>(), targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: false)
	}

	func changing(core: CoreType? = nil, incompleteChildren: Set<String>? = nil, children: Mapping<String, Value>? = nil, targets: TrieSet<String>? = nil, masks: TrieSet<String>? = nil, isMasked: Bool? = nil) -> Self {
		return Self(core: core ?? self.core, incompleteChildren: incompleteChildren ?? self.incompleteChildren, children: children ?? self.children, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked)
	}

	func capture(digestString: String, content: [Bool], prefix: Path, previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> (Self, Mapping<String, [Path]>)? {
        guard let modifiedCore = core.capture(content: content, digestString: digestString, previousKey: previousKey, keys: keys) else { return nil }
		let newChildren = modifiedCore.2.reduce((Mapping<String, Value>(), Mapping<String, [Path]>())) { (result, entry) -> (Mapping<String, Value>, Mapping<String, [Path]>) in
			let childEdge = entry.0.toString()
			let childPrefix = prefix + [childEdge]
			let childAfterTargeting = entry.1.targeting(targets.subtree(keys: [childEdge]), prefix: childPrefix)
			let childAfterMasking = childAfterTargeting.0.masking(masks.subtree(keys: [childEdge]), prefix: childPrefix)
			let childMasked = isMasked ? childAfterMasking.0.mask(prefix: childPrefix) : (childAfterMasking.0, Mapping<String, [Path]>())
			return (result.0.setting(key: childEdge, value: childMasked.0), result.1 + childAfterTargeting.1 + childAfterMasking.1 + childMasked.1)
		}
		let foundIndicies = modifiedCore.2.map { $0.0.toString() }
		let leftoverTargets = foundIndicies.reduce(targets ?? TrieSet<String>()) { (result, entry) -> TrieSet<String> in
			return result.excluding(keys: [entry])
		}
		let leftoverMasks = foundIndicies.reduce(masks ?? TrieSet<String>()) { (result, entry) -> TrieSet<String> in
			return result.excluding(keys: [entry])
		}
		let newPaths = modifiedCore.1.reduce(newChildren.1) { (result, entry) -> Mapping<String, [Path]> in
			return result.setting(key: entry, value: (result[entry] ?? []) + [prefix])
		}
		let newIncompleteChildren = newChildren.0.elements().filter { !$0.1.complete }.map { $0.0 }
		return (changing(core: modifiedCore.0, incompleteChildren: incompleteChildren.union(newIncompleteChildren), children: children.overwrite(with: newChildren.0), targets: leftoverTargets, masks: leftoverMasks), newPaths)
	}

	func capture(digestString: String, content: [Bool], at route: Path, prefix: Path, previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> (Self, Mapping<String, [Path]>)? {
		guard let firstLeg = route.first else {
			return capture(digestString: digestString, content: content, prefix: prefix, previousKey: previousKey, keys: keys)
		}
		guard let childValue = children[firstLeg] else { return nil }
		if childValue.complete { return nil }
		guard let childResult = childValue.capture(digestString: digestString, content: content, at: Array(route.dropFirst()), prefix: prefix + [firstLeg], previousKey: previousKey, keys: keys) else { return nil }
		let newChild = childResult.0
		let modifiedChildren = children.setting(key: firstLeg, value: newChild)
		if newChild.complete { return (changing(incompleteChildren: incompleteChildren.subtracting([firstLeg]), children: modifiedChildren), childResult.1) }
		return (changing(children: modifiedChildren), childResult.1)
	}

	func missing(prefix: Path) -> Mapping<String, [Path]> {
		let missingCore = core.missingDigests().reduce(Mapping<String, [Path]>()) { (result, entry) -> Mapping<String, [Path]> in
			return result.setting(key: entry, value: [prefix])
		}
		return children.elements().map { $0.1.missing(prefix: prefix + [$0.0.toString()]) }.reduce(missingCore, +)
	}

	func contents(previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> Mapping<String, [Bool]> {
		return children.elements().reduce(core.contents(previousKey: previousKey, keys: keys)) { (result, entry) -> Mapping<String, [Bool]> in
			return result.overwrite(with: entry.1.contents(previousKey: previousKey, keys: keys))
		}
	}

	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) {
		return targets.children.keys().reduce((self, Mapping<String, [Path]>()), { (result, entry) -> (Self, Mapping<String, [Path]>) in
			let targeted = result.0.targeting(targets, prefix: prefix, edge: entry)
			return (targeted.0, result.1 + targeted.1)
		})
	}

	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge], edge: String) -> (Self, Mapping<String, [Path]>) {
		if isMasked { return (self, Mapping<String, [Path]>()) }
		let targetsForKey = targets.including(keys: [edge])
		if targetsForKey.isEmpty() { return (self, Mapping<String, [Path]>()) }
		if let child = children[edge] { return targeting(child: child, targets: targetsForKey, prefix: prefix, edge: edge) }
		let newTargets = self.targets.overwrite(with: targetsForKey)
		if !self.targets.subtree(keys: [edge]).isEmpty() || !self.masks.subtree(keys: [edge]).isEmpty() {
			return (changing(targets: newTargets), Mapping<String, [Path]>())
		}
		guard let key = Key(stringValue: edge) else { return (self, Mapping<String, [Path]>()) }
		let coreResult = core.targeting(keys: [key])
		let corePaths = coreResult.1.reduce(Mapping<String, [Path]>()) { (result, entry) -> Mapping<String, [Path]> in
			return result.setting(key: entry, value: [prefix])
		}
		return (changing(core: coreResult.0, targets: newTargets), corePaths)
	}

	func targeting(child: Value, targets: TrieSet<Edge>, prefix: [Edge], edge: String) -> (Self, Mapping<String, [Path]>) {
		let keyTargets = targets.subtree(keys: [edge])
		let childResult = child.targeting(keyTargets, prefix: prefix + [edge])
		let newIncompleteChildren = (child.complete && !childResult.0.complete) ? incompleteChildren.union([edge]) : incompleteChildren
		if targets.contains([edge]) {
			let targetedChild = child.target(prefix: prefix + [edge])
			let finalIncompleteChildren = (child.complete && !targetedChild.0.complete) ? newIncompleteChildren!.union([edge]) : newIncompleteChildren!
			return (changing(incompleteChildren: finalIncompleteChildren, children: children.setting(key: edge, value: targetedChild.0)), targetedChild.1)
		}
		return (changing(incompleteChildren: newIncompleteChildren, children: children.setting(key: edge, value: childResult.0)), childResult.1)
	}

	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) {
		return masks.children.keys().reduce((self, Mapping<String, [Path]>())) { (result, entry) -> (Self, Mapping<String, [Path]>) in
			let masked = result.0.masking(masks, prefix: prefix, edge: entry)
			return (masked.0, result.1 + masked.1)
		}
	}

	func masking(_ masks: TrieSet<Edge>, prefix: [Edge], edge: String) -> (Self, Mapping<String, [Path]>) {
		let masksForKey = masks.including(keys: [edge])
		if masksForKey.isEmpty() { return (self, Mapping<String, [Path]>()) }
		if let child = children[edge] { return masking(child: child, masks: masksForKey, prefix: prefix, edge: edge) }
		let newMasks = self.masks.overwrite(with: masksForKey)
		if !self.targets.subtree(keys: [edge]).isEmpty() || !self.masks.subtree(keys: [edge]).isEmpty() {
			return (changing(masks: newMasks), Mapping<String, [Path]>())
		}
		guard let key = Key(stringValue: edge) else { return (self, Mapping<String, [Path]>()) }
		let coreResult = core.masking(keys: [key])
		let corePaths = coreResult.1.reduce(Mapping<String, [Path]>()) { (result, entry) -> Mapping<String, [Path]> in
			return result.setting(key: entry, value: [prefix])
		}
		return (changing(core: coreResult.0, masks: newMasks), corePaths)
	}

	func masking(child: Value, masks: TrieSet<Edge>, prefix: [Edge], edge: String) -> (Self, Mapping<String, [Path]>) {
		if masks.contains([edge]) {
			let maskedChild = child.mask(prefix: prefix + [edge])
			let newIncompleteChildren = (child.complete && !maskedChild.0.complete) ? incompleteChildren.union([edge]) : incompleteChildren
			return (changing(incompleteChildren: newIncompleteChildren, children: children.setting(key: edge, value: maskedChild.0)), maskedChild.1)
		}
		let keyMasks = masks.subtree(keys: [edge])
		let childResult = child.masking(keyMasks, prefix: prefix + [edge])
		let newIncompleteChildren = (child.complete && !childResult.0.complete) ? incompleteChildren.union([edge]) : incompleteChildren
		return (changing(incompleteChildren: newIncompleteChildren, children: children.setting(key: edge, value: childResult.0)), childResult.1)
	}

	func mask(prefix: [Edge]) -> (Self, Mapping<String, [Path]>) {
		let coreResult = core.mask()
		let corePaths = coreResult.1.reduce(Mapping<String, [Path]>()) { (result, entry) -> Mapping<String, [Path]> in
			return result.setting(key: entry, value: [prefix])
		}
		let newChildren = children.elements().reduce((Mapping<String, Value>(), Mapping<String, [Path]>(), Set<String>())) { (result, entry) -> (Mapping<String, Value>, Mapping<String, [Path]>, Set<String>) in
			if entry.1.isMasked { return (result.0.setting(key: entry.0, value: entry.1), result.1, result.2) }
			let childResult = entry.1.mask(prefix: prefix + [entry.0.toString()])
			let newIncompleteChildren = (entry.1.complete && !childResult.0.complete) ? [entry.0] : []
			return (result.0.setting(key: entry.0, value: childResult.0), result.1 + childResult.1, result.2.union(newIncompleteChildren))
		}
		return (changing(core: coreResult.0, incompleteChildren: incompleteChildren.union(newChildren.2), children: newChildren.0, targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: true), corePaths + newChildren.1)
	}
}
