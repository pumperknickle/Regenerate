import AwesomeDictionary
import AwesomeTrie
import Bedrock
import Foundation

public protocol RGRT: Regenerative where Root: RGRadixAddress {
    associatedtype Key: DataEncodable
    associatedtype Value: DataEncodable

    typealias Edge = Root.Edge

    func decodeKey(symbols: [Edge]) -> Data?
    func encodeKey(key: Data) -> [Edge]?
    func decodeValue(symbols: [Edge]) -> Data?
    func encodeValue(value: Data) -> [Edge]?
}

public extension RGRT {
    init?(raw: [(Key, Value)]) {
        let modifiedRRM = raw.reduce(Self()) { (result, entry) -> Self? in
            guard let result = result else { return nil }
            return result.setting(key: entry.0, to: entry.1)
        }
        guard let finalRRM = modifiedRRM else { return nil }
        self = finalRRM
    }

    // Empty Tree
    init() { self.init(root: Root(), paths: Mapping<Digest, [Path]>()) }

    var digest: Digest! { return root.fingerprint }

    func computedValidity() -> Bool { return root.computedValidity() }

    func keys() -> [Key]? {
        return root.keys().reduce([]) { (result, entry) -> [Key]? in
            guard let result = result else { return nil }
            guard let dataDecodedKey = decodeKey(symbols: entry) else { return nil }
            guard let key = Key(data: dataDecodedKey) else { return nil }
            return result + [key]
        }
    }

    func values() -> [Value]? {
        return root.values().reduce([]) { (result, entry) -> [Value]? in
            guard let result = result else { return nil }
            guard let dataDecodedValue = decodeValue(symbols: entry) else { return nil }
            guard let value = Value(data: dataDecodedValue) else { return nil }
            return result + [value]
        }
    }

    func knows(key: Key) -> Bool {
        guard let symbolEncodedKey = encodeKey(key: key.toData()) else { return false }
        return root.get(key: symbolEncodedKey) != nil
    }

    func get(key: Key) -> Value? {
        guard let symbolEncodedKey = encodeKey(key: key.toData()) else { return nil }
        guard let symbolEncodedValue = root.get(key: symbolEncodedKey) else { return nil }
        if symbolEncodedValue.isEmpty { return nil }
        guard let dataDecodedValue = decodeValue(symbols: symbolEncodedValue) else { return nil }
        return Value(data: dataDecodedValue)
    }

    func setting(key: Key, to value: Value) -> Self? {
        guard let symbolEncodedKey = encodeKey(key: key.toData()) else { return nil }
        guard let symbolEncodedValue = encodeValue(value: value.toData()) else { return nil }
        guard let modifiedRoot = root.setting(key: symbolEncodedKey, to: symbolEncodedValue) else { return nil }
        return Self(root: modifiedRoot)
    }

    func deleting(key: Key) -> Self? {
        guard let symbolEncodedKey = encodeKey(key: key.toData()) else { return nil }
        guard let modifiedRoot = root.setting(key: symbolEncodedKey, to: []) else { return nil }
        return Self(root: modifiedRoot)
    }

    func transitionProof(proofType: TransitionProofType, for key: Key) -> Self? {
        guard let symbolEncodedKey = encodeKey(key: key.toData()) else { return nil }
        guard let transitionProof = root.transitionProof(proofType: proofType, key: symbolEncodedKey) else { return nil }
        return Self(root: transitionProof)
    }

    func merging(_ right: Self) -> Self {
        let mergedRoots = root.merging(right: right.root)
        return Self(root: mergedRoots, paths: mergedRoots.missing(prefix: []).convertToStructured()!)
    }

    func capture(info: [Data], previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> (Self, [(Key, Value)])? {
        let optionalDigests = info.reduce([:]) { (result, entry) -> [Digest: Data]? in
            guard let result = result else { return nil }
            guard let digestBits = CryptoDelegateType.hash(entry) else { return nil }
            guard let digest = Digest(data: digestBits) else { return nil }
            return result.setting(digest, withValue: entry)
        }
        guard let digests = optionalDigests else { return nil }
        return capture(info: digests, previousKey: previousKey, keys: keys)
    }

    func capture(info: [Digest: Data], previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> (Self, [(Key, Value)])? {
        let insertions = keyPaths.keys().map { (digest: $0, content: info[$0]) }
        if insertions.isEmpty || !insertions.contains(where: { $0.content != nil }) { return (self, []) }
        let nextStep = insertions.reduce((self, [])) { (result, entry) -> (Self, [(Key, Value)])? in
            guard let result = result else { return nil }
            guard let content = entry.content else { return result }
            guard let rrmInsertingContent = result.0.capture(content: content, digest: entry.digest, previousKey: previousKey, keys: keys) else { return nil }
            return (rrmInsertingContent.0, rrmInsertingContent.2 + result.1)
        }
        guard let rrmAfterStep = nextStep else { return nil }
        guard let recursiveChildResult = rrmAfterStep.0.capture(info: info, previousKey: previousKey, keys: keys) else { return nil }
        return (recursiveChildResult.0, recursiveChildResult.1 + rrmAfterStep.1)
    }

    func capture(content: Data, previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> (Self, Set<Digest>, [(Key, Value)])? {
        guard let digestBytes: Data = CryptoDelegateType.hash(content) else { return nil }
        guard let digest = Digest(data: digestBytes) else { return nil }
        return capture(content: content, digest: digest, previousKey: previousKey, keys: keys)
    }

    func capture(content: Data, digest: Digest, previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> (Self, Set<Digest>, [(Key, Value)])? {
        guard let routes = keyPaths[digest] else { return nil }
        if routes.isEmpty { return nil }
        let resultAfterExploringRoutes = routes.reduce((self, Set<Digest>([]), [])) { (result, entry) -> (Self, Set<Digest>, [(Key, Value)])? in
            guard let result = result else { return nil }
            guard let rrmAfterExploringRoute = result.0.capture(digest: digest, content: content, at: entry, previousKey: previousKey, keys: keys) else { return nil }
            let newDigests = result.1.union(rrmAfterExploringRoute.1)
            guard let keyForResult = rrmAfterExploringRoute.2 else { return (rrmAfterExploringRoute.0, newDigests, result.2) }
            return (rrmAfterExploringRoute.0, newDigests, result.2 + [keyForResult])
        }
        guard let finalResult = resultAfterExploringRoutes else { return nil }
        if finalResult.1.contains(digest) { return nil }
        let finalRRM = Self(root: finalResult.0.root, paths: finalResult.0.keyPaths.deleting(key: digest))
        return (finalRRM, finalResult.1, finalResult.2)
    }

    func capture(digest: Digest, content: Data, at route: Path, previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> (Self, Set<Digest>, (Key, Value)?)? {
        guard let modifiedRootResult = root.capture(digestString: digest.toData(), content: content, at: route, prefix: [], previousKey: previousKey, keys: keys) else { return nil }
        let structured: Mapping<Digest, [Path]> = modifiedRootResult.1.convertToStructured()!
        guard let valueEdges = modifiedRootResult.0.value(for: route) else { return (Self(root: modifiedRootResult.0, paths: structured + keyPaths), Set(structured.keys()), nil) }
        if valueEdges.isEmpty { return (Self(root: modifiedRootResult.0, paths: structured + keyPaths), Set(structured.keys()), nil) }
        guard let dataDecodedValue = decodeValue(symbols: valueEdges) else { return nil }
        guard let value = Value(data: dataDecodedValue) else { return nil }
        guard let keyEdges = modifiedRootResult.0.key(for: route, prefix: []) else { return nil }
        guard let dataDecodedKey = decodeKey(symbols: keyEdges) else { return nil }
        guard let key = Key(data: dataDecodedKey) else { return nil }
        return (Self(root: modifiedRootResult.0, paths: structured + keyPaths), Set(structured.keys()), (key, value))
    }

    func targeting(keys: [Key]) -> (Self, Set<Digest>) {
        let targets = keys.reduce(TrieSet<Edge>()) { (result, entry) -> TrieSet<Edge> in
            guard let symbolEncodedKey = encodeKey(key: entry.toData()) else { return result }
            return result.adding(symbolEncodedKey)
        }
        return targeting(targets)
    }

    func masking(keys: [Key]) -> (Self, Set<Digest>) {
        let masks = keys.reduce(TrieSet<Edge>()) { (result, entry) -> TrieSet<Edge> in
            guard let symbolEncodedKey = encodeKey(key: entry.toData()) else { return result }
            return result.adding(symbolEncodedKey)
        }
        return masking(masks)
    }
}
