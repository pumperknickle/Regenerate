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
    
    var root: Root { get }
    var keyPaths: Mapping<String, [Path]> { get }
    
    init(root: Root, paths: Mapping<String, [Path]>)
	func targeting(_ targets: TrieSet<Edge>) -> (Self, Set<String>)
	func masking(_ masks: TrieSet<Edge>) -> (Self, Set<String>)
	func mask() -> (Self, Set<String>)
	func set(key: [Bool]) -> Self?
}

public extension Regenerative {
	init(root: Root) { self.init(root: root, paths: root.missing(prefix: [])) }
    
    func complete() -> Bool { return root.complete }
    
	func missingDigests() -> Set<String> { return Set(keyPaths.keys()) }
    
    func contents() -> Mapping<String, [Bool]> { return root.contents() }
    
    func cuttingAllNodes() -> Self { return Self(root: root.empty()) }
	
	func set(key: [Bool]) -> Self? {
		guard let keyHash = CryptoDelegateType.hash(key) else { return nil }
		guard let childResult = root.set(key: key, iv: keyHash) else { return nil }
		return Self(root: childResult)
	}
    
    func capture(info: [[Bool]]) -> Self? {
        let optionalDigests = info.reduce([:]) { (result, entry) -> [String: [Bool]]? in
            guard let result = result else { return nil }
            guard let digestBits = CryptoDelegateType.hash(entry) else { return nil }
            guard let digest = Digest(raw: digestBits) else { return nil }
			return result.setting(digest.toString(), withValue: entry)
        }
        guard let digests = optionalDigests else { return nil }
        let captured = capture(info: digests)
        return captured
    }
    
    func capture(info: [String: [Bool]]) -> Self? {
        let insertions = missingDigests().map { (key: $0, value: info[$0]) }
        if insertions.isEmpty || !insertions.contains(where: { $0.value != nil }) { return self } // no relevant info to insert
        let nextStep = insertions.reduce(self) { (result, entry) -> Self? in
            guard let result = result else { return nil }
            guard let content = entry.value else { return result }
            guard let childResult = result.capture(content: content, digestString: entry.key) else { return result }
            return childResult.0
        }
        guard let regenerativeAfterStep = nextStep else { return nil }
        return regenerativeAfterStep.capture(info: info)
    }
    
    func capture(content: [Bool]) -> (Self, Set<String>)? {
        guard let digestBits = CryptoDelegateType.hash(content) else { return nil }
        guard let digest = Digest(raw: digestBits) else { return nil }
		return capture(content: content, digestString: digest.toString())
    }
    
    // warning - this call assumes that the content's digest == digest. Calling this function directly without checking digest equivalency may introduce malicious information
    func capture(content: [Bool], digestString: String) -> (Self, Set<String>)? {
        guard let routes = keyPaths[digestString] else { return nil }
        if routes.isEmpty { return (self, Set<String>([])) }
        let resultExploringRoutes = routes.reduce((self, Set<String>([]))) { (result, entry) -> (Self, Set<String>)? in
            guard let result = result else { return nil }
            guard let exploringRoute = result.0.capture(digestString: digestString, content: content, at: entry) else { return result }
            return (exploringRoute.0, exploringRoute.1.union(result.1))
        }
        guard let routeResult = resultExploringRoutes else { return nil }
        if routeResult.1.contains(digestString) { return nil }
        let finalResult = Self(root: routeResult.0.root, paths: routeResult.0.keyPaths.deleting(key: digestString))
        return (finalResult, routeResult.1)
    }
    
    func capture(digestString: String, content: [Bool], at route: Path) -> (Self, Set<String>)? {
		guard let modifiedStem = root.capture(digestString: digestString, content: content, at: route, prefix: []) else { return nil }
        let newMissingDigests = modifiedStem.1.keys().filter { !keyPaths.keys().contains($0) }
        return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set(newMissingDigests))
    }

	func targeting(_ targets: TrieSet<Edge>) -> (Self, Set<String>) {
		let modifiedStem = root.targeting(targets, prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<String>(modifiedStem.1.keys()))
	}

	func masking(_ masks: TrieSet<Edge>) -> (Self, Set<String>) {
		let modifiedStem = root.masking(masks, prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<String>(modifiedStem.1.keys()))
	}
	
	func mask() -> (Self, Set<String>) {
		let modifiedStem = root.mask(prefix: [])
		return (Self(root: modifiedStem.0, paths: modifiedStem.1 + keyPaths), Set<String>(modifiedStem.1.keys()))
	}
}