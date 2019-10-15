import Foundation
import Bedrock
import AwesomeDictionary

public protocol Radix: RGArtifact where Child.Artifact == Self {
    associatedtype Child: Stem

    var prefix: [Edge] { get }
    var value: [Edge] { get }
    var children: Mapping<Edge, Child> { get }
    
    init(prefix: [Edge], value: [Edge], children: Mapping<Edge, Child>)
}

public extension Radix {
    init() { self.init(prefix: [], value: [], children: Mapping<Edge, Child>()) }
    
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
            guard let newChild = Child(artifact: node.pruning()) else { return nil }
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
                guard let newChild = Child(artifact: changing(prefix: childSuffix)) else { return nil }
                return Self(prefix: key, value: value, children: Mapping<Edge, Child>().setting(key: firstChild, value: newChild))
            }
            let sharedPrefix = prefix ~> key
            let keySuffix = key - sharedPrefix
            let nodeSuffix = prefix - sharedPrefix
            guard let firstKeySuffix = keySuffix.first else { return nil }
            guard let firstNodeSuffix = nodeSuffix.first else { return nil }
            guard let keyChild = Child(artifact: Self(prefix: keySuffix, value: value, children: Mapping<Edge, Child>())) else { return nil }
            guard let nodeChild = Child(artifact: changing(prefix: nodeSuffix)) else { return nil }
            let newChildren = Mapping<Edge, Child>().setting(key: firstKeySuffix, value: keyChild).setting(key: firstNodeSuffix, value: nodeChild)
            return Self(prefix: sharedPrefix, value: [], children: newChildren)
        }
        let suffix = key - prefix
        guard let firstSymbol = suffix.first else { return changing(value: value) }
        guard let firstStem = children[firstSymbol] else {
            guard let newStem = Child(artifact: Self(prefix: suffix, value: value, children: Mapping<Edge, Child>())) else { return nil }
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
    
    func nodeInfoAlong(firstLeg: Edge, path route: Path) -> [[Bool]]? {
        guard let child = children[firstLeg] else { return nil }
        return child.nodeInfoAlong(path: route)
    }
    
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, Mapping<Digest, [Path]>)? {
        guard let firstLeg = route.first else { return nil }
        guard let childStem = children[firstLeg] else { return nil }
        guard let childStemResult = childStem.capture(digest: digest, content: content, at: Array(route.dropFirst())) else { return nil }
        let modifiedNode = changing(children: children.setting(key: firstLeg, value: childStemResult.0))
        let routes = childStemResult.1.prepend(firstLeg)
        return (modifiedNode, routes)
    }
    
    func missing() -> Mapping<Digest, [Path]> {
        if children.isEmpty() { return Mapping<Digest, [Path]>() }
        return children.elements().map { $0.1.missing().prepend($0.0.toString()) }.reduce(Mapping<Digest, [Path]>(), +)
    }
    
    func contents() -> Mapping<Digest, [Bool]>? {
        return children.values().reduce(Mapping<Digest, [Bool]>(), { (result, entry) -> Mapping<Digest, [Bool]>? in
            guard let result = result else { return nil }
            guard let childContents = entry.contents() else { return nil }
            return result.overwrite(with: childContents)
        })
    }
}
