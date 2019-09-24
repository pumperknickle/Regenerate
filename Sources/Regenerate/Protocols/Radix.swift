import Foundation
import CryptoStarterPack

public protocol Radix: RGArtifact where Child.Artifact == Self {
    associatedtype Child: Stem
    
    var prefix: [Edge] { get }
    var value: [Edge] { get }
    var children: [Edge: Child] { get }
    
    init(prefix: [Edge], value: [Edge], children: [Edge: Child])
}

public extension Radix {
    init() { self.init(prefix: [], value: [], children: [:]) }
    
    func isValid() -> Bool {
        return !children.values.contains(where: { !$0.computedValidity() })
    }
    
    func isComplete() -> Bool {
        return !children.values.contains(where: { !$0.complete })
    }
    
    func changing(prefix: [Edge]? = nil, value: [Edge]? = nil, children: [Edge: Child]? = nil) -> Self {
        return Self(prefix: prefix == nil ? self.prefix : prefix!, value: value == nil ? self.value : value!, children: children == nil ? self.children : children!)
    }
    
    func values() -> [[Edge]] {
        return children.values.map { $0.values() }.reduce([], +) + (value.isEmpty ? [] : [value])
    }
    
    func keys() -> [[Edge]] {
        return children.values.map { $0.keys().map { prefix + $0 } }.reduce([], +) + (value.isEmpty ? [] : [prefix])
    }
    
    func pruning() -> Self {
        return changing(children: cuttingChildStems())
    }
    
    func cuttingChildStems() -> [Edge: Child] {
        return children.reduce([:] as [Edge: Child], { (result, entry) -> [Edge: Child] in
            return result.setting(entry.key, withValue: Child(digest: entry.value.digest))
        })
    }
    
    func cuttingGrandchildStems() -> [Edge: Child]? {
        return children.reduce([:] as [Edge: Child], { (result, entry) -> [Edge: Child]? in
            guard let result = result else { return nil }
            guard let node = entry.value.artifact else { return nil }
            guard let newChild = Child(artifact: node.pruning()) else { return nil }
            return result.setting(entry.key, withValue: newChild)
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
                guard let newChild = Child(artifact: changing(prefix: childSuffix)) else { return nil }
                return Self(prefix: key, value: value, children: [firstChild: newChild])
            }
            let sharedPrefix = prefix ~> key
            let keySuffix = key - sharedPrefix
            let nodeSuffix = prefix - sharedPrefix
            guard let firstKeySuffix = keySuffix.first else { return nil }
            guard let firstNodeSuffix = nodeSuffix.first else { return nil }
            guard let keyChild = Child(artifact: Self(prefix: keySuffix, value: value, children: [:])) else { return nil }
            guard let nodeChild = Child(artifact: changing(prefix: nodeSuffix)) else { return nil }
            return Self(prefix: sharedPrefix, value: [], children: [firstKeySuffix: keyChild, firstNodeSuffix: nodeChild])
        }
        let suffix = key - prefix
        guard let firstSymbol = suffix.first else { return changing(value: value) }
        guard let firstStem = children[firstSymbol] else {
            guard let newStem = Child(artifact: Self(prefix: suffix, value: value, children: [:])) else { return nil }
            return changing(children: children.setting(firstSymbol, withValue: newStem))
        }
        guard let newStem = firstStem.setting(key: suffix, to: value) else { return nil }
        return changing(children: children.setting(firstSymbol, withValue: newStem))
    }
    
    func deleting(key: [Edge]) -> Self? {
        if !key.starts(with: prefix) { return nil }
        let suffix = key - prefix
        guard let firstSymbol = suffix.first else {
            if value.isEmpty { return nil }
            if children.count > 1 { return changing(value: []) }
            guard let childResult = children.values.first else { return nil }
            guard let childResultNode = childResult.artifact else { return nil }
            return childResultNode.changing(prefix: prefix + childResultNode.prefix)
        }
        guard let childStem = children[firstSymbol] else { return nil }
        guard let result = childStem.setting(key: suffix, to: []) else {
            let newChildren = children.removing(firstSymbol)
            if !value.isEmpty || newChildren.count > 1 { return changing(children: newChildren) }
            if value.isEmpty && newChildren.isEmpty { return Self() }
            guard let childTuple = newChildren.first else { return nil }
            guard let siblingNode = childTuple.value.artifact else { return nil }
            if prefix.isEmpty { return changing(children: newChildren) }
            return siblingNode.changing(prefix: prefix + siblingNode.prefix)
        }
        return changing(children: children.setting(firstSymbol, withValue: result))
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
            return changing(children: children.setting(firstSymbol, withValue: childTransitionProof))
        }
        return changing(children: cuttingChildStems().setting(firstSymbol, withValue: childTransitionProof))
    }
    
    func merging(right: Self) -> Self {
        let newChildren = children.reduce([:] as [Edge: Child]) { (result, entry) -> [Edge: Child] in
            let mergedChildStem = self.children[entry.key]!.merging(right: right.children[entry.key]!)
            return result.setting(entry.key, withValue: mergedChildStem)
        }
        return changing(children: newChildren)
    }
    
    func nodeInfoAlong(firstLeg: Edge, path route: Path) -> [[Bool]]? {
        guard let child = children[firstLeg] else { return nil }
        return child.nodeInfoAlong(path: route)
    }
    
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, [Digest: [Path]])? {
        guard let firstLeg = route.first else { return nil }
        guard let childStem = children[firstLeg] else { return nil }
        guard let childStemResult = childStem.capture(digest: digest, content: content, at: Array(route.dropFirst())) else { return nil }
        let modifiedNode = changing(children: children.setting(firstLeg, withValue: childStemResult.0))
        let routes = childStemResult.1.prepend(firstLeg)
        return (modifiedNode, routes)
    }
    
    func missing() -> [Digest: [Path]] {
        if children.isEmpty { return [:] }
        return children.map { $0.value.missing().prepend($0.key.toString()) }.reduce([:], +)
    }
    
    func contents() -> [Digest: [Bool]]? {
        return children.values.reduce([:], { (result, entry) -> [Digest: [Bool]]? in
            guard let result = result else { return nil }
            guard let childContents = entry.contents() else { return nil }
            return result.merging(childContents)
        })
    }
    
    func toBoolArray() -> [Bool] {
        let prefixData = try! JSONEncoder().encode(prefix.map { $0.toString() })
        let valueData = try! JSONEncoder().encode(value.map { $0.toString() })
        let mappedChildren = children.mapValues { $0.digest! }
        let childKeys = mappedChildren.toSortedKeys()
        let childValues = mappedChildren.toSortedValues()
        let childKeyData = try! JSONEncoder().encode(childKeys.map { $0.toString() })
        let childValueData = try! JSONEncoder().encode(childValues.map { $0.toString() })
        return try! JSONEncoder().encode([prefixData, valueData, childKeyData, childValueData]).toBoolArray()
    }
    
    init?(raw: [Bool]) {
        guard let content = Data(raw: raw) else { return nil }
        guard let arrayObject = try? JSONDecoder().decode([Data].self, from: content) else { return nil }
        if arrayObject.count != 4 { return nil }
        guard let prefixStrings = try? JSONDecoder().decode([String].self, from: arrayObject[0]) else { return nil }
        guard let valueStrings = try? JSONDecoder().decode([String].self, from: arrayObject[1]) else { return nil }
        let prefix = prefixStrings.map { Edge(stringValue: $0) }
        let value = valueStrings.map { Edge(stringValue: $0) }
        if prefix.contains(nil) || value.contains(nil) { return nil }
        guard let childKeyStrings = try? JSONDecoder().decode([String].self, from: arrayObject[2]) else { return nil }
        guard let childValueStrings = try? JSONDecoder().decode([String].self, from: arrayObject[3]) else { return nil }
        guard let children = Dictionary<Edge, Digest>.combine(keys: childKeyStrings, values: childValueStrings) else { return nil }
        self.init(prefix: prefix.map { $0! }, value: value.map { $0! }, children: children.mapValues { Child(digest: $0) })
    }
}
