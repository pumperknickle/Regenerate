import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGRT: Regenerative where Root: RGRadixAddress {
    associatedtype Key: BinaryEncodable
    associatedtype Value: BinaryEncodable

    typealias Edge = Root.Edge

    func decodeKey(_ symbols: [Edge]) -> [Bool]?
    func encodeKey(_ key: [Bool]) -> [Edge]?
    func decodeValue(_ symbols: [Edge]) -> [Bool]?
    func encodeValue(_ value: [Bool]) -> [Edge]?
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
    init() { self.init(root: Root(), paths: Mapping<String, [Path]>()) }

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
		return Self(root: mergedRoots, paths: mergedRoots.missing(prefix: []))
    }

    func capture(info: [[Bool]], previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> (Self, [(Key, Value)])? {
        let optionalDigests = info.reduce([:]) { (result, entry) -> [String: [Bool]]? in
            guard let result = result else { return nil }
            guard let digestBits = CryptoDelegateType.hash(entry) else { return nil }
            guard let digest = Digest(raw: digestBits) else { return nil }
			return result.setting(digest.toString(), withValue: entry)
        }
        guard let digests = optionalDigests else { return nil }
        return capture(info: digests, previousKey: previousKey, keys: keys)
    }

    func capture(info: [String: [Bool]], previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> (Self, [(Key, Value)])? {
        let insertions = keyPaths.keys().map { (digest: $0, content: info[$0]) }
        if insertions.isEmpty || !insertions.contains(where: { $0.content != nil }) { return (self, []) }
        let nextStep = insertions.reduce((self, [])) { (result, entry) -> (Self, [(Key, Value)])? in
            guard let result = result else { return nil }
            guard let content = entry.content else { return result }
			guard let rrmInsertingContent = result.0.capture(content: content, digestString: entry.digest.toString(), previousKey: previousKey, keys: keys) else { return nil }
            return (rrmInsertingContent.0, rrmInsertingContent.2 + result.1)
        }
        guard let rrmAfterStep = nextStep else { return nil }
        guard let recursiveChildResult = rrmAfterStep.0.capture(info: info, previousKey: previousKey, keys: keys) else { return nil }
        return (recursiveChildResult.0, recursiveChildResult.1 + rrmAfterStep.1)
    }

    func capture(content: [Bool], previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> (Self, Set<String>, [(Key, Value)])? {
        guard let digestBits = CryptoDelegateType.hash(content) else { return nil }
        guard let digest = Digest(raw: digestBits) else { return nil }
		return capture(content: content, digestString: digest.toString(), previousKey: previousKey, keys: keys)
    }

    func capture(content: [Bool], digestString: String, previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> (Self, Set<String>, [(Key, Value)])? {
        guard let routes = keyPaths[digestString] else { return nil }
        if routes.isEmpty { return nil }
        let resultAfterExploringRoutes = routes.reduce((self, Set<String>([]), [])) { (result, entry) -> (Self, Set<String>, [(Key, Value)])? in
            guard let result = result else { return nil }
            guard let rrmAfterExploringRoute = result.0.capture(digestString: digestString, content: content, at: entry, previousKey: previousKey, keys: keys) else { return nil }
            let newDigests = result.1.union(rrmAfterExploringRoute.1)
            guard let keyForResult = rrmAfterExploringRoute.2 else { return (rrmAfterExploringRoute.0, newDigests, result.2) }
            return (rrmAfterExploringRoute.0, newDigests, result.2 + [keyForResult])
        }
        guard let finalResult = resultAfterExploringRoutes else { return nil }
        if finalResult.1.contains(digestString) { return nil }
        let finalRRM = Self(root: finalResult.0.root, paths: finalResult.0.keyPaths.deleting(key: digestString))
		return (finalRRM, finalResult.1, finalResult.2)
    }

    func capture(digestString: String, content: [Bool], at route: Path, previousKey: [Bool]?, keys: TrieMapping<Bool, [Bool]>) -> (Self, Set<String>, (Key, Value)?)? {
		guard let modifiedRootResult = root.capture(digestString: digestString, content: content, at: route, prefix: [], previousKey: previousKey, keys: keys) else { return nil }
		guard let valueEdges = modifiedRootResult.0.value(for: route) else { return (Self(root: modifiedRootResult.0, paths: modifiedRootResult.1 + keyPaths), Set(modifiedRootResult.1.keys()), nil) }
		if valueEdges.isEmpty { return (Self(root: modifiedRootResult.0, paths: modifiedRootResult.1 + keyPaths), Set(modifiedRootResult.1.keys()), nil) }
		guard let binaryDecodedValue = decodeValue(valueEdges) else { return nil }
		guard let value = Value(raw: binaryDecodedValue) else { return nil }
		guard let keyEdges = modifiedRootResult.0.key(for: route, prefix: []) else { return nil }
		guard let binaryDecodedKey = decodeKey(keyEdges) else { return nil }
		guard let key = Key(raw: binaryDecodedKey) else { return nil }
		return (Self(root: modifiedRootResult.0, paths: modifiedRootResult.1 + keyPaths), Set(modifiedRootResult.1.keys()), (key, value))
    }

	func targeting(keys: [Key]) -> (Self, Set<String>) {
		let targets = keys.reduce(TrieSet<Edge>()) { (result, entry) -> TrieSet<Edge> in
			guard let symbolEncodedKey = encodeKey(entry.toBoolArray()) else { return result }
			return result.adding(symbolEncodedKey)
		}
		return targeting(targets)
	}

	func masking(keys: [Key]) -> (Self, Set<String>) {
		let masks = keys.reduce(TrieSet<Edge>()) { (result, entry) -> TrieSet<Edge> in
			guard let symbolEncodedKey = encodeKey(entry.toBoolArray()) else { return result }
			return result.adding(symbolEncodedKey)
		}
		return masking(masks)
	}
}
