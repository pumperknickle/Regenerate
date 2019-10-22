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
