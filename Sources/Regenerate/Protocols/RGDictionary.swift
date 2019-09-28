import Foundation
import Bedrock
import TMap

public protocol RGDictionary: RGArtifact {
    associatedtype Key: Stringable
    associatedtype Value: CID where Value.Digest == Digest
    associatedtype CoreType: RGRT where CoreType.Key == Key, CoreType.Value == Value, CoreType.Digest == Digest
    
    typealias CoreRootType = CoreType.Root
    
    var core: CoreType! { get }
    var mapping: [Key: Value]! { get }
    var incompleteChildren: Set<Key>! { get }
    
    init(core: CoreType, mapping: [Key: Value], incomplete: Set<Key>)
}

public extension RGDictionary {
    init?(_ rawDictionary: [Key: Value]) {
        let coreTuples = rawDictionary.map { ($0.key, $0.value) }
        guard let core = CoreType(raw: coreTuples) else { return nil }
        self.init(core: core, mapping: rawDictionary, incomplete: Set([]))
    }
    
    init(root: CoreRootType) {
        self.init(core: CoreType(root: root))
    }
    
    init(core: CoreType) {
        self.init(core: core, mapping: [:], incomplete: Set([]))
    }
    
    func setting(key: Key, to value: Value) -> Self? {
        if !isComplete() || !value.complete { return nil }
        guard let modifiedCore = core.setting(key: key, to: value) else { return nil }
        return Self(core: modifiedCore, mapping: mapping.setting(key, withValue: value), incomplete: Set([]))
    }
    
    func changing(core: CoreType? = nil, mapping: [Key: Value]? = nil, incompleteChildren: Set<Key>? = nil) -> Self {
        return Self(core: core == nil ? self.core : core!, mapping: mapping == nil ? self.mapping : mapping!, incomplete: incompleteChildren == nil ? self.incompleteChildren : incompleteChildren!)
    }
    
    func keyToRouteSegment(_ key: Key) -> Edge { return key.toString() }
    
    func routeSegmentToKey(_ routeSegment: Edge) -> Key? { return Key(stringValue: routeSegment) }
    
    func isComplete() -> Bool { return core.complete() && incompleteChildren.isEmpty }
    
    func pruning() -> Self {
        return Self(core: CoreType(root: core.root.empty()), mapping: [:], incomplete: Set([]))
    }
    
    func discover(incompleteKeys: [Key]) -> Self {
        return changing(incompleteChildren: incompleteChildren.union(incompleteKeys))
    }
    
    func complete(keys: [Key]) -> Self {
        return changing(incompleteChildren: incompleteChildren.subtracting(keys))
    }
    
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, TMap<Digest, [Path]>)? {
        guard let firstLeg = route.first else {
            guard let insertionResult = core.capture(content: content, digest: digest) else { return nil }
            let modifiedMapping = insertionResult.2.reduce(mapping, { (result, entry) -> [Key: Value] in
                return result.setting(entry.0, withValue: entry.1)
            })
            let newMappingRoutes = insertionResult.2.reduce(TMap<Digest, [Path]>()) { (result, entry) -> TMap<Digest, [Path]> in
                return result.setting(key: entry.1.digest, value: [[keyToRouteSegment(entry.0)]])
            }
            let newRoutes = insertionResult.1.reduce(newMappingRoutes) { (result, entry) -> TMap<Digest, [Path]> in
                guard let oldRoutes = result[entry] else { return result.setting(key: entry, value: [[]]) }
                return result.setting(key: entry, value: oldRoutes + [[]])
            }
            let keysDiscoveredIncomplete = insertionResult.2.map { $0.0 }
            return (changing(core: insertionResult.0, mapping: modifiedMapping).discover(incompleteKeys: keysDiscoveredIncomplete), newRoutes)
        }
        guard let childKey = Key(stringValue: firstLeg) else { return nil }
        guard let childStem = mapping[childKey] else { return nil }
        if childStem.complete { return nil }
        guard let modifiedChildResult = childStem.capture(digest: digest, content: content, at: Array(route.dropFirst())) else { return nil }
        let modifiedMapping = mapping.setting(childKey, withValue: modifiedChildResult.0)
        if modifiedChildResult.0.complete {
            return (changing(mapping: modifiedMapping).complete(keys: [childKey]), modifiedChildResult.1.prepend(firstLeg))
        }
        return (changing(mapping: modifiedMapping), modifiedChildResult.1.prepend(firstLeg))
    }
    
    func missing() -> TMap<Digest, [Path]> {
        let missingChildrenInCore = core.missingDigests().reduce(TMap<Digest, [Path]>()) { (result, entry) -> TMap<Digest, [Path]> in
            return result.setting(key: entry, value: [[]])
        }
        return mapping.map { $0.value.missing().prepend(keyToRouteSegment($0.key)) }.reduce(missingChildrenInCore, +)
    }
    
    func contents() -> TMap<Digest, [Bool]>? {
        guard let coreContents = core.root.contents() else { return nil }
        return mapping.values.reduce(coreContents, { (result, entry) -> TMap<Digest, [Bool]>? in
            guard let result = result else { return nil }
            guard let childContents = entry.contents() else { return nil }
            return result.overwrite(with: childContents)
        })
    }    
}
