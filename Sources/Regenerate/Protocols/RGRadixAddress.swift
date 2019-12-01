import Foundation

public protocol RGRadixAddress: Addressable where Artifact: RGRadix, Artifact.Child == Self { }

public enum TransitionProofType: Int {
    case creation = 1, mutation, deletion
}

public extension RGRadixAddress {
    init() { self.init(artifact: Artifact(), symmetricKeyHash: nil, symmetricIV: nil)! }

    func get(key: [Edge]) -> [Edge]? {
        guard let node = artifact else { return nil }
        return node.get(key: key)
    }

	func value(for route: Path) -> [Edge]? {
		guard let artifact = artifact else { return nil }
		return artifact.value(for: route)
	}

	func key(for route: Path, prefix: [Edge]) -> [Edge]? {
		guard let artifact = artifact else { return nil }
		return artifact.key(for: route, prefix: prefix)
	}

    func values() -> [[Edge]] {
        guard let node = artifact else { return [] }
        return Array(Set(node.values()))
    }

    func keys() -> [[Edge]] {
        guard let node = artifact else { return [] }
        return node.keys()
    }

    func computedValidity() -> Bool {
        guard let node = artifact else { return true }
        guard let hashOutput = CryptoDelegateType.hash(node.toBoolArray()) else { return false }
        guard let nodeHash = Digest(raw: hashOutput) else { return false }
        if digest != nodeHash { return false }
        return !node.children.values().contains(where: { !$0.computedValidity() })
    }

    // warning, calling this creates a NEW rrm with a new digest
    func setting(key: [Edge], to value: [Edge]) -> Self? {
        guard let node = artifact else { return nil }
		guard let modifiedNode = value.isEmpty ? node.deleting(key: key) : node.setting(key: key, to: value) else { return nil }
        return Self(artifact: modifiedNode, symmetricKeyHash: nil, symmetricIV: symmetricIV)
    }

    func setting(all: [(key: [Edge], value: [Edge])]) -> Self? {
        guard let firstTuple = all.first else { return self }
        guard let result = setting(key: firstTuple.key, to: firstTuple.value) else { return nil }
        return result.setting(all: Array(all.dropFirst()))
    }

    func transitionProof(proofType: TransitionProofType, key: [Edge]) -> Self? {
        guard let node = artifact else { return nil }
        guard let transitionProof = node.transitionProof(proofType: proofType, key: key) else { return nil }
        return Self(artifact: transitionProof, symmetricKeyHash: symmetricKeyHash, symmetricIV: symmetricIV)
    }

    func merging(right: Self) -> Self {
        if artifact == nil && right.artifact == nil { return self }
        guard let leftNode = artifact else { return right }
        guard let rightNode = right.artifact else { return self }
        guard let mergedStem = Self(artifact: leftNode.merging(right: rightNode), symmetricKeyHash: symmetricKeyHash, symmetricIV: symmetricIV) else { return self }
        return mergedStem
    }
}
