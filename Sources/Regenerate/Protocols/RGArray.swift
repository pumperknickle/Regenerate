//import Foundation
//import Bedrock
//import AwesomeDictionary
//import AwesomeTrie
//
//public protocol RGArray: RGArtifact {
//	associatedtype Index: FixedWidthInteger, Stringable
//	associatedtype Element: CID where Element.Digest == Digest
//	associatedtype CoreType: RGRT where CoreType.Key == Index, CoreType.Value == Element.Digest, CoreType.Digest == Digest
//	typealias CoreRoot = CoreType.Root
//	
//	var core: CoreType! { get }
//	var length: Index! { get }
//	var incompleteChildren: Set<Index>! { get }
//	var children: Mapping<Index, Element>! { get }
//	var targets: TrieSet<Edge>! { get }
//	var masks: TrieSet<Edge>! { get }
//	var isMasked: Bool! { get }
//	
//	init(core: CoreType, length: Index, incompleteChildren: Set<Index>, children: Mapping<Index, Element>, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool)
//}
//
//public extension RGArray {
//	init?(_ rawArray: [Element]) {
//		let indexing = rawArray.reduce((Mapping<Index, Element>(), Index(0))) { (result, entry) -> (Mapping<Index, Element>, Index)? in
//			guard let result = result else { return nil }
//			return (result.0.setting(key: result.1, value: entry), result.1.advanced(by: 1))
//		}
//		guard let indexedResult = indexing else { return nil }
//		let coreTuples = indexedResult.0.elements().map { ($0.0, $0.1.digest!) }
//		guard let core = CoreType(raw: coreTuples) else { return nil }
//		self.init(core: core, length: indexedResult.1, incompleteChildren: Set<Index>([]), children: indexedResult.0, targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: false)
//	}
//	
//	init(core: CoreType, length: Index, incompleteChildren: Set<Index>, children: Mapping<Index, Element>) {
//		self.init(core: core, length: length, incompleteChildren: incompleteChildren, children: children, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: false)
//	}
//	
//	init(core: CoreType, length: Index) {
//		self.init(core: core, length: length, incompleteChildren: Set<Index>([]), children: Mapping<Index, Element>(), targets: TrieSet<String>(), masks: TrieSet<String>(), isMasked: false)
//	}
//	
//	init(root: CoreRoot, length: Index) {
//		self.init(core: CoreType(root: root), length: length)
//	}
//	
//	func isComplete() -> Bool {
//		return core.complete() && !children.values().contains(where: { !$0.complete })
//	}
//	
//	func pruning() -> Self {
//		return Self(core: CoreType(root: core.root.empty()), length: length)
//	}
//	
//	func changing(core: CoreType? = nil, incompleteChildren: Set<Index>? = nil, children: Mapping<Index, Element>? = nil, targets: TrieSet<String>? = nil, masks: TrieSet<String>? = nil, isMasked: Bool? = nil) -> Self {
//		return Self(core: core ?? self.core, length: length, incompleteChildren: incompleteChildren ?? self.incompleteChildren, children: children ?? self.children, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked)
//	}
//
//	func capture(digest: Digest, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<Digest, [Path]>)? {
//		guard let firstLeg = route.first else {
//			return capture(digest: digest, content: content, prefix: prefix)
//		}
//		guard let childIndex = Index(stringValue: firstLeg) else { return nil }
//		guard let childElement = children[childIndex] else { return nil }
//		if childElement.complete { return nil }
//		guard let childResult = childElement.capture(digest: digest, content: content, at: Array(route.dropFirst()), prefix: prefix + [firstLeg]) else { return nil }
//		let newChild = childResult.0
//		let modifiedChildren = children.setting(key: childIndex, value: newChild)
//		if newChild.complete { return (changing(children: modifiedChildren).complete(keys: [childIndex]), childResult.1) }
//		return (changing(children: modifiedChildren), childResult.1)
//	}
//	
//	func capture(digest: Digest, content: [Bool], prefix: Path) -> (Self, Mapping<Digest, [Path]>)? {
//		guard let modifiedCore = core.capture(content: content, digest: digest) else { return nil }
//		let newChildren = modifiedCore.2.reduce((Mapping<Index, Element>(), Mapping<Digest, [Path]>())) { (result, entry) -> (Mapping<Index, Element>, Mapping<Digest, [Path]>) in
//			let childEdge = entry.0.toString()
//			let childPrefix = prefix + [childEdge]
//			let childAfterTargeting = Element(digest: entry.1).targeting(targets.including(keys: [childEdge]).subtree(keys: [childEdge]), prefix: childPrefix)
//			let childAfterMasking = childAfterTargeting.0.masking(masks.including(keys: [childEdge]).subtree(keys: [childEdge]), prefix: childPrefix)
//			let childMasked = isMasked ? childAfterMasking.0.mask(prefix: childPrefix) : (childAfterMasking.0, Mapping<Digest, [Path]>())
//			return (result.0.setting(key: entry.0, value: childMasked.0), result.1 + childAfterTargeting.1 + childAfterMasking.1 + childMasked.1)
//		}
//		let foundIndicies = modifiedCore.2.map { $0.0.toString() }
//		let leftoverTargets = foundIndicies.reduce(targets ?? TrieSet<String>()) { (result, entry) -> TrieSet<String> in
//			return result.excluding(keys: [entry.toString()])
//		}
//		let leftoverMasks = foundIndicies.reduce(masks ?? TrieSet<String>()) { (result, entry) -> TrieSet<String> in
//			return result.excluding(keys: [entry.toString()])
//		}
//		let newPaths = modifiedCore.1.reduce(newChildren.1) { (result, entry) -> Mapping<Digest, [Path]> in
//			return result.setting(key: entry, value: (result[entry] ?? []) + [prefix])
//		}
//		let newIncompleteChildren = newChildren.0.elements().filter { !$0.1.complete }.map { $0.0 }
//		return (changing(core: modifiedCore.0, incompleteChildren: incompleteChildren.union(newIncompleteChildren), children: children.overwrite(with: newChildren.0), targets: leftoverTargets, masks: leftoverMasks), newPaths)
//	}
//	
//	func complete(keys: [Index]) -> Self {
//		return changing(incompleteChildren: incompleteChildren.subtracting(keys))
//	}
//	
//	func discover(incomplete: [Index]) -> Self {
//		return changing(incompleteChildren: incompleteChildren.union(incomplete))
//	}
//	
//	func missing(prefix: Path) -> Mapping<Digest, [Path]> {
//		let missingCore = core.missingDigests().reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
//			return result.setting(key: entry, value: [prefix])
//		}
//		return children.elements().map { $0.1.missing(prefix: prefix + [$0.0.toString()]) }.reduce(missingCore, +)
//	}
//	
//	func contents() -> Mapping<Digest, [Bool]>? {
//		guard let coreContents = core.contents() else { return nil }
//		return children.values().reduce(coreContents, { (result, entry) -> Mapping<Digest, [Bool]>? in
//			guard let result = result else { return nil }
//			guard let childContent = entry.contents() else { return nil }
//			return result.overwrite(with: childContent)
//		})
//	}
//	
//	func appending(_ element: Element) -> Self? {
//		if !isComplete() || !element.complete { return nil }
//		guard let modifiedCore = core.setting(key: length, to: element.digest) else { return nil }
//		let newLength = length.advanced(by: 1)
//		return Self(core: modifiedCore, length: newLength, incompleteChildren: Set<Index>(), children: children.setting(key: newLength, value: element))
//	}
//	
//	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>) {
//		targets.children.keys()
//	}
//	
//	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge], key: String) -> (Self, Mapping<Digest, [Path]>) {
//		guard let index = Index(stringValue: key) else { return (self, Mapping<Digest, [Path]>()) }
//		if targets.isEmpty() { return (self, Mapping<Digest, [Path]>()) }
//		if let child = children[index] {
//			let childResult = child.targeting(targets, prefix: prefix + [key])
//			return (changing(children: children.setting(key: index, value: childResult.0)), childResult.1)
//		}
//		chil
//	}
//}

//import Foundation
//import Bedrock
//import AwesomeDictionary
//
//public protocol RGArray: RGArtifact {
//    associatedtype Index: FixedWidthInteger, Stringable
//    associatedtype Element: CID where Element.Digest == Digest
//    associatedtype CoreType: RGRT where CoreType.Key == Index, CoreType.Value == Element.Digest, CoreType.Digest == Digest
//    typealias CoreRootType = CoreType.Root
//    
//    var core: CoreType! { get }
//    var length: Index! { get }
//    var mapping: Mapping<Index, Element>! { get }
//    var completeChildren: Set<Index>! { get }
//    
//    init(core: CoreType, length: Index, mapping: Mapping<Index, Element>, complete: Set<Index>)
//}
//
//public extension RGArray {
//    init?(_ rawArray: [Element]) {
//        let resultOfIndexing = rawArray.reduce((Mapping<Index, Element>(), Index(0))) { (result, entry) -> (Mapping<Index, Element>, Index)? in
//            guard let result = result else { return nil }
//            return (result.0.setting(key: result.1, value: entry), result.1.advanced(by: 1))
//        }
//        guard let finalIndexingResult = resultOfIndexing else { return nil }
//        let mapping = finalIndexingResult.0
//        if mapping.elements().contains(where: { $0.1.digest == nil }) { return nil }
//        let complete = Set(mapping.keys())
//        let coreTuples = mapping.elements().map { ($0.0, $0.1.digest!) }
//        guard let core = CoreType(raw: coreTuples) else { return nil }
//        self.init(core: core, length: finalIndexingResult.1, mapping: mapping, complete: complete)
//    }
//    
//    init(root: CoreRootType, length: Index) {
//        self.init(core: CoreType(root: root), length: length)
//    }
//    
//    init(core: CoreType, length: Index) {
//        self.init(core: core, length: length, mapping: Mapping<Index, Element>(), complete: Set([]))
//    }
//    
//    func indexToRouteSegment(_ index: Index) -> Edge {
//        return index.toString()
//    }
//    
//    func routeSegmentToIndex(_ routeSegment: Edge) -> Index? {
//        return Index(stringValue: routeSegment)
//    }
//    
//    func isComplete() -> Bool {
//        return core.complete() && Index(completeChildren.count) == length
//    }
//    
//    func pruning() -> Self {
//        return Self(core: CoreType(root: core.root.empty()), length: length, mapping: Mapping<Index, Element>(), complete: Set([]))
//    }
//    
//    func changing(core: CoreType? = nil, mapping: Mapping<Index, Element>? = nil, complete: Set<Index>? = nil) -> Self {
//        return Self(core: core == nil ? self.core : core!, length: length, mapping: mapping == nil ? self.mapping : mapping!, complete: complete == nil ? self.completeChildren : complete!)
//    }
//    
//    func completing(indices: [Index]) -> Self {
//        return changing(complete: completeChildren.union(indices))
//    }
//    
//	func capture(digest: Digest, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<Digest, [Path]>)? {
//        guard let firstLeg = route.first else {
//            guard let insertionResult = core.capture(content: content, digest: digest) else { return nil }
//            let modifiedMapping = insertionResult.2.reduce(mapping) { (result, entry) -> Mapping<Index, Element> in
//                return result.setting(key: entry.0, value: Element(digest: entry.1))
//            }
//            let newMappingRoutes = insertionResult.2.reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
//                return result.setting(key: entry.1, value: [prefix + [indexToRouteSegment(entry.0)]])
//            }
//            let allRoutes = insertionResult.1.reduce(newMappingRoutes) { (result, entry) -> Mapping<Digest, [Path]> in
//                guard let oldRoutes = result[entry] else { return result.setting(key: entry, value: [prefix]) }
//                return result.setting(key: entry, value: oldRoutes + [prefix])
//            }
//            return (changing(core: insertionResult.0, mapping: modifiedMapping), allRoutes)
//        }
//        guard let childIndex = routeSegmentToIndex(firstLeg) else { return nil }
//        guard let childElement = mapping[childIndex] else { return nil }
//        if childElement.complete { return nil }
//		guard let modifiedChildResult = childElement.capture(digest: digest, content: content, at: Array(route.dropFirst()), prefix: prefix + [firstLeg]) else { return nil }
//        let modifiedMapping = mapping.setting(key: childIndex, value: modifiedChildResult.0)
//		if modifiedChildResult.0.complete { return (changing(mapping: modifiedMapping).completing(indices: [childIndex]), modifiedChildResult.1) }
//        return (changing(mapping: modifiedMapping), modifiedChildResult.1)
//    }
//    
//    func missing() -> Mapping<Digest, [Path]> {
//        let missingChildrenInCore = core.missingDigests().reduce(Mapping<Digest, [Path]>()) { (result, entry) -> Mapping<Digest, [Path]> in
//            return result.setting(key: entry, value: [[]])
//        }
//        return mapping.elements().map { $0.1.missing().prepend(indexToRouteSegment($0.0)) }.reduce(missingChildrenInCore, +)
//    }
//    
//    func contents() -> Mapping<Digest, [Bool]>? {
//        guard let coreContents = core.contents() else { return nil }
//        return mapping.values().reduce(coreContents, { (result, entry) -> Mapping<Digest, [Bool]>? in
//            guard let result = result else { return nil }
//            guard let childContent = entry.contents() else { return nil }
//            return result.overwrite(with: childContent)
//        })
//    }
//    
//    func appending(_ element: Element) -> Self? {
//        if !isComplete() || !element.complete { return nil }
//        guard let modifiedCore = core.setting(key: length, to: element.digest) else { return nil }
//        let newLength = length.advanced(by: 1)
//        return Self(core: modifiedCore, length: newLength, mapping: mapping.setting(key: newLength, value: element), complete: completeChildren.union([newLength]))
//    }
//}
