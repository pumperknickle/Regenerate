import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGDictionary: RGArtifact {
	associatedtype Key: Stringable
	associatedtype Value: CID where Value.Digest == Digest
	associatedtype CoreType: RGRT where CoreType.Key == Key, CoreType.Value == Value, CoreType.Digest == Digest
	typealias CoreRoot = CoreType.Root

	var core: CoreType! { get }
	var incompleteChildren: Set<Key>! { get }
	var children: Mapping<Key, Value>! { get }
	var targets: TrieSet<Edge>! { get }
	var masks: TrieSet<Edge>! { get }
	var isMasked: Bool! { get }
	
	init(core: CoreType, incompleteChildren: Set<Key>, children: Mapping<Key, Value>, targets: TrieSet<String>, masks: TrieSet<String>, isMasked: Bool)
}

public extension RGDictionary {
	init?(_ mapping: Mapping<Key, Value>) {
		let coreTuples = mapping.elements()
		let children = coreTuples.reduce(Mapping<Key, Value>()) { (result, entry) -> Mapping<Key, Value> in
			return result.setting(key: entry.0, value: entry.1)
		}
		guard let core = CoreType(raw: coreTuples) else { return nil }
		self.init(core: core, incompleteChildren: Set([]), children: children, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: false)
	}
		
	func isComplete() -> Bool {
		return core.complete() && !children.values().contains(where: { !$0.complete })
	}
	
	func pruning() -> Self {
		return Self(core: CoreType(root: core.root.empty()), incompleteChildren: Set<Key>(), children: Mapping<Key, Value>(), targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: false)
	}
	
	func changing(core: CoreType? = nil, incompleteChildren: Set<Key>? = nil, children: Mapping<Key, Value>? = nil, targets: TrieSet<String>? = nil, masks: TrieSet<String>? = nil, isMasked: Bool? = nil) -> Self {
		return Self(core: core ?? self.core, incompleteChildren: incompleteChildren ?? self.incompleteChildren, children: children ?? self.children, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked)
	}

	func capture(digest: Digest, content: [Bool], prefix: Path) -> (Self, Mapping<Digest, [Path]>)? {
		guard let modifiedCore = core.capture(content: content, digest: digest) else { return nil }
		let newChildren = modifiedCore.2.reduce((Mapping<Key, Value>(), Mapping<Digest, [Path]>())) { (result, entry) -> (Mapping<Key, Value>, Mapping<Digest, [Path]>) in
			let childEdge = entry.0.toString()
			let childPrefix = prefix + [childEdge]
			let childAfterTargeting = entry.1.targeting(targets.subtree(keys: [childEdge]), prefix: childPrefix)
			let childAfterMasking = childAfterTargeting.0.masking(masks.subtree(keys: [childEdge]), prefix: childPrefix)
			let childMasked = isMasked ? childAfterMasking.0.mask(prefix: childPrefix) : (childAfterMasking.0, Mapping<Digest, [Path]>())
			return (result.0.setting(key: entry.0, value: childMasked.0), result.1 + childAfterTargeting.1 + childAfterMasking.1 + childMasked.1)
		}
		let foundIndicies = modifiedCore.2.map { $0.0.toString() }
		let leftoverTargets = foundIndicies.reduce(targets ?? TrieSet<String>()) { (result, entry) -> TrieSet<String> in
			return result.excluding(keys: [entry.toString()])
		}
		let leftoverMasks = foundIndicies.reduce(masks ?? TrieSet<String>()) { (result, entry) -> TrieSet<String> in
			return result.excluding(keys: [entry.toString()])
		}
		let newPaths = modifiedCore.1.reduce(newChildren.1) { (result, entry) -> Mapping<Digest, [Path]> in
			return result.setting(key: entry, value: (result[entry] ?? []) + [prefix])
		}
		let newIncompleteChildren = newChildren.0.elements().filter { !$0.1.complete }.map { $0.0 }
		return (changing(core: modifiedCore.0, incompleteChildren: incompleteChildren.union(newIncompleteChildren), children: children.overwrite(with: newChildren.0), targets: leftoverTargets, masks: leftoverMasks), newPaths)
	}
	
	func capture(digest: Digest, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<Digest, [Path]>)? {
		guard let firstLeg = route.first else {
			return capture(digest: digest, content: content, prefix: prefix)
		}
		guard let childKey = Key(stringValue: firstLeg) else { return nil }
		guard let childValue = children[childKey] else { return nil }
		if childValue.complete { return nil }
		guard let childResult = childValue.capture(digest: digest, content: content, at: Array(route.dropFirst()), prefix: prefix + [firstLeg]) else { return nil }
		let newChild = childResult.0
		let modifiedChildren = children.setting(key: childKey, value: newChild)
		if newChild.complete { return (changing(incompleteChildren: incompleteChildren.subtracting([childKey]), children: modifiedChildren), childResult.1) }
		return (changing(children: modifiedChildren), childResult.1)
	}
	
	func missing(prefix: Path) -> Mapping<Digest, [Path]> {
		let missingCore = core.missingDigests().reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
			return result.setting(key: entry, value: [prefix])
		}
		return children.elements().map { $0.1.missing(prefix: prefix + [$0.0.toString()]) }.reduce(missingCore, +)
	}
	
	func contents() -> Mapping<Digest, [Bool]>? {
		guard let coreContents = core.contents() else { return nil }
		return children.values().reduce(coreContents, { (result, entry) -> Mapping<Digest, [Bool]>? in
			guard let result = result else { return nil }
			guard let childContent = entry.contents() else { return nil }
			return result.overwrite(with: childContent)
		})
	}
	
	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>) {
		return targets.children.keys().reduce((self, Mapping<Digest, [Path]>()), { (result, entry) -> (Self, Mapping<Digest, [Path]>) in
			let targeted = result.0.targeting(targets, prefix: prefix, edge: entry)
			return (targeted.0, result.1 + targeted.1)
		})
	}
	
	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge], edge: String) -> (Self, Mapping<Digest, [Path]>) {
		if isMasked { return (self, Mapping<Digest, [Path]>()) }
		guard let key = Key(stringValue: edge) else { return (self, Mapping<Digest, [Path]>()) }
		let targetsForKey = targets.including(keys: [edge])
		if targetsForKey.isEmpty() { return (self, Mapping<Digest, [Path]>()) }
		if let child = children[key] { return targeting(child: child, targets: targetsForKey, prefix: prefix, edge: edge, key: key) }
		let newTargets = self.targets.overwrite(with: targetsForKey)
		if !self.targets.subtree(keys: [edge]).isEmpty() || !self.masks.subtree(keys: [edge]).isEmpty() {
			return (changing(targets: newTargets), Mapping<Digest, [Path]>())
		}
		let coreResult = core.targeting(keys: [key])
		let corePaths = coreResult.1.reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
			return result.setting(key: entry, value: [prefix])
		}
		return (changing(core: coreResult.0, targets: newTargets), corePaths)
	}
	
	func targeting(child: Value, targets: TrieSet<Edge>, prefix: [Edge], edge: String, key: Key) -> (Self, Mapping<Digest, [Path]>) {
		let keyTargets = targets.subtree(keys: [edge])
		let childResult = child.targeting(keyTargets, prefix: prefix + [edge])
		let newIncompleteChildren = (child.complete && !childResult.0.complete) ? incompleteChildren.union([key]) : incompleteChildren
		return (changing(incompleteChildren: newIncompleteChildren, children: children.setting(key: key, value: childResult.0)), childResult.1)
	}
	
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>) {
		return masks.children.keys().reduce((self, Mapping<Digest, [Path]>())) { (result, entry) -> (Self, Mapping<Digest, [Path]>) in
			let masked = result.0.masking(masks, prefix: prefix, edge: entry)
			return (masked.0, result.1 + masked.1)
		}
	}
	
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge], edge: String) -> (Self, Mapping<Digest, [Path]>) {
		guard let key = Key(stringValue: edge) else { return (self, Mapping<Digest, [Path]>()) }
		let masksForKey = masks.including(keys: [edge])
		if masksForKey.isEmpty() { return (self, Mapping<Digest, [Path]>()) }
		if let child = children[key] { return masking(child: child, masks: masksForKey, prefix: prefix, edge: edge, key: key) }
		let newMasks = self.masks.overwrite(with: masksForKey)
		if !self.targets.subtree(keys: [edge]).isEmpty() || !self.masks.subtree(keys: [edge]).isEmpty() {
			return (changing(masks: newMasks), Mapping<Digest, [Path]>())
		}
		let coreResult = core.masking(keys: [key])
		let corePaths = coreResult.1.reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
			return result.setting(key: entry, value: [prefix])
		}
		return (changing(core: coreResult.0, masks: newMasks), corePaths)
	}
	
	func masking(child: Value, masks: TrieSet<Edge>, prefix: [Edge], edge: String, key: Key) -> (Self, Mapping<Digest, [Path]>) {
		if masks.contains([edge]) {
			let maskedChild = child.mask(prefix: prefix + [edge])
			let newIncompleteChildren = (child.complete && !maskedChild.0.complete) ? incompleteChildren.union([key]) : incompleteChildren
			return (changing(incompleteChildren: newIncompleteChildren, children: children.setting(key: key, value: maskedChild.0)), maskedChild.1)
		}
		let keyMasks = masks.subtree(keys: [edge])
		let childResult = child.masking(keyMasks, prefix: prefix + [edge])
		let newIncompleteChildren = (child.complete && !childResult.0.complete) ? incompleteChildren.union([key]) : incompleteChildren
		return (changing(incompleteChildren: newIncompleteChildren, children: children.setting(key: key, value: childResult.0)), childResult.1)
	}
	
	func mask(prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>) {
		let coreResult = core.mask()
		let corePaths = coreResult.1.reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
			return result.setting(key: entry, value: [prefix])
		}
		let newChildren = children.elements().reduce((Mapping<Key, Value>(), Mapping<Digest, [Path]>(), Set<Key>())) { (result, entry) -> (Mapping<Key, Value>, Mapping<Digest, [Path]>, Set<Key>) in
			if entry.1.isMasked { return (result.0.setting(key: entry.0, value: entry.1), result.1, result.2) }
			let childResult = entry.1.mask(prefix: prefix + [entry.0.toString()])
			let newIncompleteChildren = (entry.1.complete && !childResult.0.complete) ? [entry.0] : []
			return (result.0.setting(key: entry.0, value: childResult.0), result.1 + childResult.1, result.2.union(newIncompleteChildren))
		}
		return (changing(core: coreResult.0, incompleteChildren: incompleteChildren.union(newChildren.2), children: newChildren.0, targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: true), corePaths + newChildren.1)
	}
}

//import Foundation
//import Bedrock
//import AwesomeDictionary
//
//public protocol RGDictionary: RGArtifact {
//    associatedtype Key: Stringable
//    associatedtype Value: CID where Value.Digest == Digest
//    associatedtype CoreType: RGRT where CoreType.Key == Key, CoreType.Value == Value, CoreType.Digest == Digest
//    
//    typealias CoreRootType = CoreType.Root
//    
//    var core: CoreType! { get }
//    var mapping: [Key: Value]! { get }
//    var incompleteChildren: Set<Key>! { get }
//    
//    init(core: CoreType, mapping: [Key: Value], incomplete: Set<Key>)
//}
//
//public extension RGDictionary {
//    init?(_ rawDictionary: [Key: Value]) {
//        let coreTuples = rawDictionary.map { ($0.key, $0.value) }
//        guard let core = CoreType(raw: coreTuples) else { return nil }
//        self.init(core: core, mapping: rawDictionary, incomplete: Set([]))
//    }
//    
//    init(root: CoreRootType) {
//        self.init(core: CoreType(root: root))
//    }
//    
//    init(core: CoreType) {
//        self.init(core: core, mapping: [:], incomplete: Set([]))
//    }
//    
//    func setting(key: Key, to value: Value) -> Self? {
//        if !isComplete() || !value.complete { return nil }
//        guard let modifiedCore = core.setting(key: key, to: value) else { return nil }
//        return Self(core: modifiedCore, mapping: mapping.setting(key, withValue: value), incomplete: Set([]))
//    }
//    
//    func changing(core: CoreType? = nil, mapping: [Key: Value]? = nil, incompleteChildren: Set<Key>? = nil) -> Self {
//        return Self(core: core == nil ? self.core : core!, mapping: mapping == nil ? self.mapping : mapping!, incomplete: incompleteChildren == nil ? self.incompleteChildren : incompleteChildren!)
//    }
//    
//    func keyToRouteSegment(_ key: Key) -> Edge { return key.toString() }
//    
//    func routeSegmentToKey(_ routeSegment: Edge) -> Key? { return Key(stringValue: routeSegment) }
//    
//    func isComplete() -> Bool { return core.complete() && incompleteChildren.isEmpty }
//    
//    func pruning() -> Self {
//        return Self(core: CoreType(root: core.root.empty()), mapping: [:], incomplete: Set([]))
//    }
//    
//    func discover(incompleteKeys: [Key]) -> Self {
//        return changing(incompleteChildren: incompleteChildren.union(incompleteKeys))
//    }
//    
//    func complete(keys: [Key]) -> Self {
//        return changing(incompleteChildren: incompleteChildren.subtracting(keys))
//    }
//    
//	func capture(digest: Digest, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<Digest, [Path]>)? {
//        guard let firstLeg = route.first else {
//            guard let insertionResult = core.capture(content: content, digest: digest) else { return nil }
//            let modifiedMapping = insertionResult.2.reduce(mapping, { (result, entry) -> [Key: Value] in
//                return result.setting(entry.0, withValue: entry.1)
//            })
//            let newMappingRoutes = insertionResult.2.reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
//                return result.setting(key: entry.1.digest, value: [prefix + [keyToRouteSegment(entry.0)]])
//            }
//            let newRoutes = insertionResult.1.reduce(newMappingRoutes) { (result, entry) -> Mapping<Digest, [Path]> in
//                guard let oldRoutes = result[entry] else { return result.setting(key: entry, value: [prefix]) }
//                return result.setting(key: entry, value: oldRoutes + [prefix])
//            }
//            let keysDiscoveredIncomplete = insertionResult.2.map { $0.0 }
//            return (changing(core: insertionResult.0, mapping: modifiedMapping).discover(incompleteKeys: keysDiscoveredIncomplete), newRoutes)
//        }
//        guard let childKey = Key(stringValue: firstLeg) else { return nil }
//        guard let childStem = mapping[childKey] else { return nil }
//        if childStem.complete { return nil }
//		guard let modifiedChildResult = childStem.capture(digest: digest, content: content, at: Array(route.dropFirst()), prefix: prefix + [firstLeg]) else { return nil }
//        let modifiedMapping = mapping.setting(childKey, withValue: modifiedChildResult.0)
//        if modifiedChildResult.0.complete {
//            return (changing(mapping: modifiedMapping).complete(keys: [childKey]), modifiedChildResult.1)
//        }
//        return (changing(mapping: modifiedMapping), modifiedChildResult.1)
//    }
//    
//    func missing() -> Mapping<Digest, [Path]> {
//        let missingChildrenInCore = core.missingDigests().reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
//            return result.setting(key: entry, value: [[]])
//        }
//        return mapping.map { $0.value.missing().prepend(keyToRouteSegment($0.key)) }.reduce(missingChildrenInCore, +)
//    }
//    
//    func contents() -> Mapping<Digest, [Bool]>? {
//        guard let coreContents = core.root.contents() else { return nil }
//        return mapping.values.reduce(coreContents, { (result, entry) -> Mapping<Digest, [Bool]>? in
//            guard let result = result else { return nil }
//            guard let childContents = entry.contents() else { return nil }
//            return result.overwrite(with: childContents)
//        })
//    }    
//}
