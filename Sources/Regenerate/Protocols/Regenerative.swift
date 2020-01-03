import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol Regenerative: Codable {
    associatedtype Root: Addressable
    typealias CryptoDelegateType = Root.CryptoDelegateType
    typealias Digest = Root.Digest
    typealias Edge = Root.Edge
    typealias Path = Root.Path
    typealias Artifact = Root.Artifact

    var root: Root { get }
    // change this to data
    var keyPaths: Mapping<Data, [Path]> { get }

    init(root: Root, paths: Mapping<Data, [Path]>)
	func targeting(_ targets: TrieSet<Edge>) -> (Self, Set<Data>)
	func masking(_ masks: TrieSet<Edge>) -> (Self, Set<Data>)
	func mask() -> (Self, Set<Data>)
}

public extension Regenerative {
	init(root: Root) { self.init(root: root, paths: root.missing(prefix: [])) }
    
    init?(artifact: Artifact?) {
        guard let artifact = artifact else { return nil }
        guard let address = Root(artifact: artifact, complete: true) else { return nil }
        self.init(root: address)
    }
    
    func empty() -> Self { return Self(root: root.empty()) }

    func complete() -> Bool { return root.complete }

	func missingDigests() -> Set<Data> { return Set(keyPaths.keys()) }
    
    func contents(previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> Mapping<Data, Data> { return root.contents(previousKey: previousKey, keys: keys) }

    func cuttingAllNodes() -> Self { return Self(root: root.empty()) }
    
    func encrypt(allKeys: CoveredTrie<String, Data>, commonIv: Data) -> Self? {
        if !missingDigests().isEmpty { return nil }
        guard let encryptedRoot = root.encrypt(allKeys: allKeys, commonIv: commonIv, keyRoot: allKeys.cover != nil) else { return nil }
        return Self(root: encryptedRoot, paths: Mapping<Data, [Path]>())
    }

    
    func capture(info: [Data], previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> Self? {
        let optionalDigests = info.reduce([:]) { (result, entry) -> [Data: Data]? in
            guard let result = result else { return nil }
            guard let digestBytes = CryptoDelegateType.hash(entry) else { return nil }
            guard let digest = Digest(data: digestBytes) else { return nil }
            return result.setting(digest.toData(), withValue: entry)
        }
        guard let digests = optionalDigests else { return nil }
        let captured = capture(info: digests, previousKey: previousKey, keys: keys)
        return captured
    }
    
    func capture(info: [Data: Data], previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> Self? {
        let insertions = missingDigests().map { (key: $0, value: info[$0]) }
        if insertions.isEmpty || !insertions.contains(where: { $0.value != nil }) { return self } // no relevant info to insert
        let nextStep = insertions.reduce(self) { (result, entry) -> Self? in
            guard let result = result else { return nil }
            guard let content = entry.value else { return result }
            guard let childResult = result.capture(content: content, digestString: entry.key, previousKey: previousKey, keys: keys) else { return result }
            return childResult.0
        }
        guard let regenerativeAfterStep = nextStep else { return nil }
        return regenerativeAfterStep.capture(info: info, previousKey: previousKey, keys: keys)
    }
    
    func capture(content: Data, previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> (Self, Set<Data>)? {
        guard let digestBytes = CryptoDelegateType.hash(content) else { return nil }
        guard let digest = Digest(data: digestBytes) else { return nil }
        return capture(content: content, digestString: digest.toData(), previousKey: previousKey, keys: keys)
    }

    // warning - this call assumes that the content's digest == digest. Calling this function directly without checking digest equivalency may introduce malicious information
    func capture(content: Data, digestString: Data, previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> (Self, Set<Data>)? {
        guard let routes = keyPaths[digestString] else { return nil }
        if routes.isEmpty { return (self, Set<Data>([])) }
        let resultExploringRoutes = routes.reduce((self, Set<Data>([]))) { (result, entry) -> (Self, Set<Data>)? in
            guard let result = result else { return nil }
            guard let exploringRoute = result.0.capture(digestString: digestString, content: content, at: entry, previousKey: previousKey, keys: keys) else { return result }
            return (exploringRoute.0, exploringRoute.1.union(result.1))
        }
        guard let routeResult = resultExploringRoutes else { return nil }
        if routeResult.1.contains(digestString) { return nil }
        let finalResult = Self(root: routeResult.0.root, paths: routeResult.0.keyPaths.deleting(key: digestString))
        return (finalResult, routeResult.1)
    }
    
    func capture(digestString: Data, content: Data, at route: Path, previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> (Self, Set<Data>)? {
        guard let modifiedStem = root.capture(digestString: digestString, content: content, at: route, prefix: [], previousKey: previousKey, keys: keys) else { return nil }
        let newMissingDigests = modifiedStem.1.keys().filter { !keyPaths.keys().contains($0) }
        return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set(newMissingDigests))
    }
    
    func query(_ queryString: String) -> Self? {
        guard let trie = TrieSet<Edge>(queryString: queryString) else { return nil }
        return targeting(trie).0
    }
    
    func queryAll(_ queryString: String) -> Self? {
        guard let trie = TrieSet<Edge>(queryString: queryString) else { return nil }
        return masking(trie).0
    }

	func targeting(_ targets: TrieSet<Edge>) -> (Self, Set<Data>) {
		let modifiedStem = root.targeting(targets, prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<Data>(modifiedStem.1.keys()))
	}

	func masking(_ masks: TrieSet<Edge>) -> (Self, Set<Data>) {
		let modifiedStem = root.masking(masks, prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<Data>(modifiedStem.1.keys()))
	}

	func mask() -> (Self, Set<Data>) {
		let modifiedStem = root.mask(prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<Data>(modifiedStem.1.keys()))
	}
}
