import Foundation

public protocol RGRadixAddress: Addressable where Artifact: RGRadix, Artifact.Child == Self {}

public enum TransitionProofType: Int {
    case creation = 1, mutation, deletion
}

public extension RGRadixAddress {
    init() { self.init(dataItem: Artifact(), fingerprintOfSymmetricKey: nil, symmetricIV: nil)! }

    func get(key: [Edge]) -> [Edge]? {
        guard let node = dataItem else { return nil }
        return node.get(key: key)
    }

    func value(for route: Path) -> [Edge]? {
        guard let artifact = dataItem else { return nil }
        return artifact.value(for: route)
    }

    func key(for route: Path, prefix: [Edge]) -> [Edge]? {
        guard let artifact = dataItem else { return nil }
        return artifact.key(for: route, prefix: prefix)
    }

    func values() -> [[Edge]] {
        guard let node = dataItem else { return [] }
        return Array(Set(node.values()))
    }

    func keys() -> [[Edge]] {
        guard let node = dataItem else { return [] }
        return node.keys()
    }

    func computedValidity() -> Bool {
        guard let node = dataItem else { return true }
        guard let hashOutput = CryptoDelegateType.hash(node.toData()) else { return false }
        guard let nodeHash = Digest(data: hashOutput) else { return false }
        if fingerprint != nodeHash { return false }
        return !node.children.values().contains(where: { !$0.computedValidity() })
    }

    // warning, calling this creates a NEW rrm with a new digest
    func setting(key: [Edge], to value: [Edge]) -> Self? {
        guard let node = dataItem else { return nil }
        guard let modifiedNode = value.isEmpty ? node.deleting(key: key) : node.setting(key: key, to: value) else { return nil }
        return Self(dataItem: modifiedNode, fingerprintOfSymmetricKey: nil, symmetricIV: symmetricIV)
    }

    func setting(all: [(key: [Edge], value: [Edge])]) -> Self? {
        guard let firstTuple = all.first else { return self }
        guard let result = setting(key: firstTuple.key, to: firstTuple.value) else { return nil }
        return result.setting(all: Array(all.dropFirst()))
    }

    func transitionProof(proofType: TransitionProofType, key: [Edge]) -> Self? {
        guard let node = dataItem else { return nil }
        guard let transitionProof = node.transitionProof(proofType: proofType, key: key) else { return nil }
        return Self(dataItem: transitionProof, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, symmetricIV: symmetricIV)
    }

    func merging(right: Self) -> Self {
        if dataItem == nil, right.dataItem == nil { return self }
        guard let leftNode = dataItem else { return right }
        guard let rightNode = right.dataItem else { return self }
        guard let mergedStem = Self(dataItem: leftNode.merging(right: rightNode), fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, symmetricIV: symmetricIV) else { return self }
        return mergedStem
    }
}
