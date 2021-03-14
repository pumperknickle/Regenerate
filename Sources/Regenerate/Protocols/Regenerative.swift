import AwesomeDictionary
import AwesomeTrie
import Bedrock
import Foundation

public protocol Regenerative: Codable {
    associatedtype Root: Addressable
    typealias CryptoDelegateType = Root.CryptoDelegateType
    typealias Digest = Root.Digest
    typealias Edge = Root.Edge
    typealias Path = Root.Path
    typealias Artifact = Root.Artifact
    typealias SymmetricKey = Root.SymmetricKey

    var root: Root { get }
    // change this to data
    var keyPaths: Mapping<Digest, [Path]> { get }

    init(root: Root, paths: Mapping<Digest, [Path]>)
    func targeting(_ targets: TrieSet<Edge>) -> (Self, Set<Digest>)
    func masking(_ masks: TrieSet<Edge>) -> (Self, Set<Digest>)
    func mask() -> (Self, Set<Digest>)
}

public extension Regenerative {
    init(root: Root) { self.init(root: root, paths: root.missing(prefix: []).convertToStructured()!) }

    init?(artifact: Artifact?) {
        guard let artifact = artifact else { return nil }
        guard let address = Root(artifact: artifact, complete: true) else { return nil }
        self.init(root: address)
    }

    func empty() -> Self { return Self(root: root.empty()) }

    func complete() -> Bool { return root.complete }

    func missingDigests() -> Set<Digest> { return Set(keyPaths.keys()) }

    func contents(previousKey: Data? = nil, keys: Mapping<Digest, Data> = Mapping<Digest, Data>()) -> Mapping<Digest, Data> { return root.contents(previousKey: previousKey, keys: keys.convertToData()).convertToStructured()! }

    func cuttingAllNodes() -> Self { return Self(root: root.empty()) }

    func encrypt(allKeys: CoveredTrie<String, Data>) -> Self? {
        if !missingDigests().isEmpty { return nil }
        guard let encryptedRoot = root.encrypt(allKeys: allKeys, keyRoot: allKeys.cover != nil) else { return nil }
        return Self(root: encryptedRoot, paths: Mapping<Digest, [Path]>())
    }

    func capture(info: [Data], previousKey: Data? = nil, keys: Mapping<Digest, Data> = Mapping<Digest, Data>()) -> Self? {
        let optionalDigests = info.reduce([:]) { (result, entry) -> [Digest: Data]? in
            guard let result = result else { return nil }
            guard let digestBytes = CryptoDelegateType.hash(entry) else { return nil }
            guard let digest = Digest(data: digestBytes) else { return nil }
            return result.setting(digest, withValue: entry)
        }
        guard let digests = optionalDigests else { return nil }
        let captured = capture(info: digests, previousKey: previousKey, keys: keys)
        return captured
    }

    func capture(info: [Digest: Data], previousKey: Data? = nil, keys: Mapping<Digest, Data> = Mapping<Digest, Data>()) -> Self? {
        let insertions = missingDigests().map { (key: $0, value: info[$0]) }
        if insertions.isEmpty || !insertions.contains(where: { $0.value != nil }) { return self } // no relevant info to insert
        let nextStep = insertions.reduce(self) { (result, entry) -> Self? in
            guard let result = result else { return nil }
            guard let content = entry.value else { return result }
            guard let childResult = result.capture(content: content, CID: entry.key, previousKey: previousKey, keys: keys) else { return result }
            return childResult.0
        }
        guard let regenerativeAfterStep = nextStep else { return nil }
        return regenerativeAfterStep.capture(info: info, previousKey: previousKey, keys: keys)
    }

    func capture(content: Data, previousKey: Data? = nil, keys: Mapping<Digest, Data> = Mapping<Digest, Data>()) -> (Self, Set<Digest>)? {
        guard let digestBytes = CryptoDelegateType.hash(content) else { return nil }
        guard let digest = Digest(data: digestBytes) else { return nil }
        return capture(content: content, CID: digest, previousKey: previousKey, keys: keys)
    }

    // warning - this call assumes that the content's digest == digest. Calling this function directly without checking digest equivalency may introduce malicious information
    func capture(content: Data, CID: Digest, previousKey: Data? = nil, keys: Mapping<Digest, Data> = Mapping<Digest, Data>()) -> (Self, Set<Digest>)? {
        guard let routes = keyPaths[CID] else { return nil }
        if routes.isEmpty { return (self, Set<Digest>([])) }
        let resultExploringRoutes = routes.reduce((self, Set<Digest>([]))) { (result, entry) -> (Self, Set<Digest>)? in
            guard let result = result else { return nil }
            guard let exploringRoute = result.0.capture(CID: CID, content: content, at: entry, previousKey: previousKey, keys: keys) else { return result }
            return (exploringRoute.0, exploringRoute.1.union(result.1))
        }
        guard let routeResult = resultExploringRoutes else { return nil }
        if routeResult.1.contains(CID) { return nil }
        let finalResult = Self(root: routeResult.0.root, paths: routeResult.0.keyPaths.deleting(key: CID))
        return (finalResult, routeResult.1)
    }

    func capture(CID: Digest, content: Data, at route: Path, previousKey: Data? = nil, keys: Mapping<Digest, Data> = Mapping<Digest, Data>()) -> (Self, Set<Digest>)? {
        guard let modifiedStem = root.capture(digestString: CID.toData(), content: content, at: route, prefix: [], previousKey: previousKey, keys: keys.convertToData()) else { return nil }
        let structured: Mapping<Digest, [Path]> = modifiedStem.1.convertToStructured()!
        let newMissingDigests = structured.keys().filter { !keyPaths.keys().contains($0) }
        return (Self(root: modifiedStem.0, paths: structured + keyPaths), Set(newMissingDigests))
    }

    func query(_ queryString: String) -> Self? {
        guard let trie = TrieSet<Edge>(queryString: queryString) else { return nil }
        return targeting(trie).0
    }

    func queryAll(_ queryString: String) -> Self? {
        guard let trie = TrieSet<Edge>(queryString: queryString) else { return nil }
        return masking(trie).0
    }

    func targeting(_ targets: TrieSet<Edge>) -> (Self, Set<Digest>) {
        let modifiedStem = root.targeting(targets, prefix: [])
        let structured: Mapping<Digest, [Path]> = modifiedStem.1.convertToStructured()!
        return (Self(root: modifiedStem.0, paths: structured + keyPaths), Set<Digest>(structured.keys()))
    }

    func masking(_ masks: TrieSet<Edge>) -> (Self, Set<Digest>) {
        let modifiedStem = root.masking(masks, prefix: [])
        let structured: Mapping<Digest, [Path]> = modifiedStem.1.convertToStructured()!
        return (Self(root: modifiedStem.0, paths: structured + keyPaths), Set<Digest>(structured.keys()))
    }

    func mask() -> (Self, Set<Digest>) {
        let modifiedStem = root.mask(prefix: [])
        let structured: Mapping<Digest, [Path]> = modifiedStem.1.convertToStructured()!
        return (Self(root: modifiedStem.0, paths: structured + keyPaths), Set<Digest>(structured.keys()))
    }
}
