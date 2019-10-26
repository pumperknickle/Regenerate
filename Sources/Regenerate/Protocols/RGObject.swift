import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGObject: Codable {
    associatedtype Root: CID
    typealias CryptoDelegateType = Root.CryptoDelegateType
    typealias Digest = Root.Digest
    typealias Edge = Root.Edge
    typealias Path = Root.Path
    
    var root: Root { get }
    var keyPaths: Mapping<Digest, [Path]> { get }
    
    init(root: Root, paths: Mapping<Digest, [Path]>)
	func targeting(_ targets: TrieSet<Edge>) -> (Self, Set<Digest>)
	func masking(_ masks: TrieSet<Edge>) -> (Self, Set<Digest>)
	func mask() -> (Self, Set<Digest>)
}

public extension RGObject {
	init(root: Root) { self.init(root: root, paths: root.missing(prefix: [])) }
    
    func complete() -> Bool { return root.complete }
    
	func missingDigests() -> Set<Digest> { return Set(keyPaths.keys()) }
    
    func contents() -> Mapping<Digest, [Bool]>? { return root.contents() }
    
    func cuttingAllNodes() -> Self { return Self(root: root.empty()) }
    
    func capture(info: [[Bool]]) -> Self? {
        let optionalDigests = info.reduce([:]) { (result, entry) -> [Digest: [Bool]]? in
            guard let result = result else { return nil }
            guard let digestBits = CryptoDelegateType.hash(entry) else { return nil }
            guard let digest = Digest(raw: digestBits) else { return nil }
            return result.setting(digest, withValue: entry)
        }
        guard let digests = optionalDigests else { return nil }
        let captured = capture(info: digests)
        return captured
    }
    
    func capture(info: [Digest: [Bool]]) -> Self? {
        let insertions = missingDigests().map { (key: $0, value: info[$0]) }
        if insertions.isEmpty || !insertions.contains(where: { $0.value != nil }) { return self } // no relevant info to insert
        let nextStep = insertions.reduce(self) { (result, entry) -> Self? in
            guard let result = result else { return nil }
            guard let content = entry.value else { return result }
            guard let childResult = result.capture(content: content, digest: entry.key) else { return result }
            return childResult.0
        }
        guard let regenerativeAfterStep = nextStep else { return nil }
        return regenerativeAfterStep.capture(info: info)
    }
    
    func capture(content: [Bool]) -> (Self, Set<Digest>)? {
        guard let digestBits = CryptoDelegateType.hash(content) else { return nil }
        guard let digest = Digest(raw: digestBits) else { return nil }
        return capture(content: content, digest: digest)
    }
    
    // warning - this call assumes that the content's digest == digest. Calling this function directly without checking digest equivalency may introduce malicious information
    func capture(content: [Bool], digest: Digest) -> (Self, Set<Digest>)? {
        guard let routes = keyPaths[digest] else { return nil }
        if routes.isEmpty { return (self, Set<Digest>([])) }
        let resultExploringRoutes = routes.reduce((self, Set<Digest>([]))) { (result, entry) -> (Self, Set<Digest>)? in
            guard let result = result else { return nil }
            guard let exploringRoute = result.0.capture(digest: digest, content: content, at: entry) else { return result }
            return (exploringRoute.0, exploringRoute.1.union(result.1))
        }
        guard let routeResult = resultExploringRoutes else { return nil }
        if routeResult.1.contains(digest) { return nil }
        let finalResult = Self(root: routeResult.0.root, paths: routeResult.0.keyPaths.deleting(key: digest))
        return (finalResult, routeResult.1)
    }
    
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, Set<Digest>)? {
		guard let modifiedStem = root.capture(digest: digest, content: content, at: route, prefix: []) else { return nil }
        let newMissingDigests = modifiedStem.1.keys().filter { !keyPaths.keys().contains($0) }
        return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set(newMissingDigests))
    }

	func targeting(_ targets: TrieSet<Edge>) -> (Self, Set<Digest>) {
		let modifiedStem = root.targeting(targets, prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<Digest>(modifiedStem.1.keys()))
	}

	func masking(_ masks: TrieSet<Edge>) -> (Self, Set<Digest>) {
		let modifiedStem = root.masking(masks, prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<Digest>(modifiedStem.1.keys()))
	}
	
	func mask() -> (Self, Set<Digest>) {
		let modifiedStem = root.mask(prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<Digest>(modifiedStem.1.keys()))
	}
}
