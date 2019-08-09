import Foundation
import CryptoStarterPack

// regenerative radix tree
public protocol RGRT: RGObject where Root: Stem {
    associatedtype Key: BinaryEncodable
    associatedtype Value: BinaryEncodable
    typealias Symbol = Root.Symbol
    func decodeKey(_ symbols: [Symbol]) -> [Bool]?
    func encodeKey(_ key: [Bool]) -> [Symbol]?
    func decodeValue(_ symbols: [Symbol]) -> [Bool]?
    func encodeValue(_ value: [Bool]) -> [Symbol]?
}

public extension RGRT {
    init?(raw: [(Key, Value)]) {
        let modifiedRRM = raw.reduce(Self(), { (result, entry) -> Self? in
            guard let result = result else { return nil }
            return result.setting(key: entry.0, to: entry.1)
        })
        guard let finalRRM = modifiedRRM else { return nil }
        self = finalRRM
    }
    
    // Empty Tree
    init() { self.init(root: Root(), paths: [:]) }
    
    var digest: Digest! { return root.digest }
    
    func computedValidity() -> Bool { return root.computedValidity() }
    
    func keys() -> [Key]? {
        return root.keys().reduce([], { (result, entry) -> [Key]? in
            guard let result = result else { return nil }
            guard let binaryDecodedKey = decodeKey(entry) else { return nil }
            guard let key = Key(raw: binaryDecodedKey) else { return nil }
            return result + [key]
        })
    }
    
    func values() -> [Value]? {
        return root.values().reduce([], { (result, entry) -> [Value]? in
            guard let result = result else { return nil }
            guard let binaryDecodedValue = decodeValue(entry) else { return nil }
            guard let value = Value(raw: binaryDecodedValue) else { return nil }
            return result + [value]
        })
    }
    
    func knows(key: Key) -> Bool {
        guard let symbolEncodedKey = encodeKey(key.toBoolArray()) else { return false }
        return root.get(key: symbolEncodedKey) != nil
    }
    
    func get(key: Key) -> Value? {
        guard let symbolEncodedKey = encodeKey(key.toBoolArray()) else { return nil }
        guard let symbolEncodedValue = root.get(key: symbolEncodedKey) else { return nil }
        if symbolEncodedValue.isEmpty { return nil }
        guard let binaryDecodedValue = decodeValue(symbolEncodedValue) else { return nil }
        return Value(raw: binaryDecodedValue)
    }
    
    func setting(key: Key, to value: Value) -> Self? {
        guard let symbolEncodedKey = encodeKey(key.toBoolArray()) else { return nil }
        guard let symbolEncodedValue = encodeValue(value.toBoolArray()) else { return nil }
        guard let modifiedRoot = root.setting(key: symbolEncodedKey, to: symbolEncodedValue) else { return nil }
        return Self(root: modifiedRoot)
    }
    
    func deleting(key: Key) -> Self? {
        guard let symbolEncodedKey = encodeKey(key.toBoolArray()) else { return nil }
        guard let modifiedRoot = root.setting(key: symbolEncodedKey, to: []) else { return nil }
        return Self(root: modifiedRoot)
    }
    
    func transitionProof(proofType: TransitionProofType, for key: Key) -> Self? {
        guard let symbolEncodedKey = encodeKey(key.toBoolArray()) else { return nil }
        guard let transitionProof = root.transitionProof(proofType: proofType, key: symbolEncodedKey) else { return nil }
        return Self(root: transitionProof)
    }
    
    func merging(_ right: Self) -> Self {
        let mergedRoots = root.merging(right: right.root)
        return Self(root: mergedRoots, paths: mergedRoots.missing())
    }
    
    func capture(info: [Data]) -> (Self, [(Key, Value)])? {
        let optionalDigests = info.reduce([:]) { (result, entry) -> [Digest: Data]? in
            guard let result = result else { return nil }
            guard let digestBits = CryptoDelegateType.hash(entry) else { return nil }
            guard let digest = Digest(raw: digestBits) else { return nil }
            return result.setting(digest, withValue: entry)
        }
        guard let digests = optionalDigests else { return nil }
        return capture(info: digests)
    }
    
    func capture(info: [Digest: Data]) -> (Self, [(Key, Value)])? {
        let insertions = keyPaths.keys.map { (digest: $0, content: info[$0]) }
        if insertions.isEmpty || !insertions.contains(where: { $0.content != nil }) { return (self, []) }
        let nextStep = insertions.reduce((self, [])) { (result, entry) -> (Self, [(Key, Value)])? in
            guard let result = result else { return nil }
            guard let content = entry.content else { return result }
            guard let rrmInsertingContent = result.0.capture(content: content, digest: entry.digest) else { return nil }
            return (rrmInsertingContent.0, rrmInsertingContent.2 + result.1)
        }
        guard let rrmAfterStep = nextStep else { return nil }
        guard let recursiveChildResult = rrmAfterStep.0.capture(info: info) else { return nil }
        return (recursiveChildResult.0, recursiveChildResult.1 + rrmAfterStep.1)
    }
    
    func capture(content: Data) -> (Self, Set<Digest>, [(Key, Value)])? {
        guard let digestBits = CryptoDelegateType.hash(content) else { return nil }
        guard let digest = Digest(raw: digestBits) else { return nil }
        return capture(content: content, digest: digest)
    }
    
    func capture(content: Data, digest: Digest) -> (Self, Set<Digest>, [(Key, Value)])? {
        guard let routes = keyPaths[digest] else { return nil }
        if routes.isEmpty { return nil }
        let resultAfterExploringRoutes = routes.reduce((self, Set<Digest>([]), [])) { (result, entry) -> (Self, Set<Digest>, [Key])? in
            guard let result = result else { return nil }
            guard let rrmAfterExploringRoute = result.0.capture(digest: digest, content: content, at: entry) else { return nil }
            let newDigests = result.1.union(rrmAfterExploringRoute.1)
            guard let keyForResult = rrmAfterExploringRoute.2 else { return (rrmAfterExploringRoute.0, newDigests, result.2) }
            return (rrmAfterExploringRoute.0, newDigests, result.2 + [keyForResult])
        }
        guard let finalResult = resultAfterExploringRoutes else { return nil }
        if finalResult.1.contains(digest) { return nil }
        let finalRRM = Self(root: finalResult.0.root, paths: finalResult.0.keyPaths.removing(digest))
        guard let insertedNode = Root.Artifact(content: content) else { return nil }
        if insertedNode.value.isEmpty { return (finalRRM, finalResult.1, []) }
        guard let binaryDecodedValue = decodeValue(insertedNode.value) else { return nil }
        guard let value = Value(raw: binaryDecodedValue) else { return nil }
        return (finalRRM, finalResult.1, finalResult.2.map { ($0, value) })
    }
    
    func capture(digest: Digest, content: Data, at route: Path) -> (Self, Set<Digest>, Key?)? {
        guard let modifiedRootResult = root.capture(digest: digest, content: content, at: route) else { return nil }
        guard let nodeInfo = modifiedRootResult.0.nodeInfoAlong(path: route) else { return nil }
        let nodes = nodeInfo.map { Root.Artifact(content: $0) }
        if nodes.contains(where: { $0 == nil }) { return nil }
        let allSymbolsAlongPath = nodes.map { $0!.prefix }.reduce([], +)
        guard let binaryDecodedKey = decodeKey(allSymbolsAlongPath) else { return nil }
        if binaryDecodedKey.isEmpty { return (Self(root: modifiedRootResult.0, paths: modifiedRootResult.1 + keyPaths), Set(modifiedRootResult.1.keys), nil)  }
        guard let key = Key(raw: binaryDecodedKey) else { return nil }
        return (Self(root: modifiedRootResult.0, paths: modifiedRootResult.1 + keyPaths), Set(modifiedRootResult.1.keys), key)
    }
}
