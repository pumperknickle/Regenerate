import Foundation

public protocol Stem: CID where Artifact: Radix, Artifact.Child == Self {
    typealias Symbol = Artifact.Symbol
}

public enum TransitionProofType: Int {
    case creation = 1, mutation, deletion
}

public extension Stem {
    init() { self.init(artifact: Artifact())! }
    
    func get(key: [Symbol]) -> [Symbol]? {
        guard let node = artifact else { return nil }
        return node.get(key: key)
    }
    
    func values() -> [[Symbol]] {
        guard let node = artifact else { return [] }
        return Array(Set(node.values()))
    }
    
    func keys() -> [[Symbol]] {
        guard let node = artifact else { return [] }
        return node.keys()
    }
    
    func computedValidity() -> Bool {
        guard let node = artifact else { return true }
        guard let nodeHash = node.hash() else { return false }
        if digest != nodeHash { return false }
        return !node.children.values.contains(where: { !$0.computedValidity() })
    }
    
    // warning, calling this creates a NEW rrm with a new digest
    func setting(key: [Symbol], to value: [Symbol]) -> Self? {
        guard let node = artifact else { return nil }
        guard let modifiedNode = value.isEmpty ? node.deleting(key: key) : node.setting(key: key, to: value) else { return nil }
        return Self(artifact: modifiedNode)
    }
    
    func setting(all: [(key: [Symbol], value: [Symbol])]) -> Self? {
        guard let firstTuple = all.first else { return self }
        guard let result = setting(key: firstTuple.key, to: firstTuple.value) else { return nil }
        return result.setting(all: Array(all.dropFirst()))
    }
    
    func transitionProof(proofType: TransitionProofType, key: [Symbol]) -> Self? {
        guard let node = artifact else { return nil }
        guard let transitionProof = node.transitionProof(proofType: proofType, key: key) else { return nil }
        return Self(artifact: transitionProof)
    }
    
    func merging(right: Self) -> Self {
        if artifact == nil && right.artifact == nil { return self }
        guard let leftNode = artifact else { return right }
        guard let rightNode = right.artifact else { return self }
        guard let mergedStem = Self(artifact: leftNode.merging(right: rightNode)) else { return self }
        return mergedStem
    }
    
    func nodeInfoAlong(path: Path) -> [[Bool]]? {
        guard let node = artifact else { return nil }
        guard let firstLeg = path.first else { return [node.toBoolArray()] }
        guard let childResult = node.nodeInfoAlong(firstLeg: firstLeg, path: Array(path.dropFirst())) else { return nil }
        return [node.toBoolArray()] + childResult
    }
}
