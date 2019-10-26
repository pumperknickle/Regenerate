import Foundation
import Bedrock
import CryptoStarterPack
import AwesomeDictionary
import AwesomeTrie

public protocol Addressable: CryptoBindable, Codable, BinaryEncodable {
	associatedtype Digest: FixedWidthInteger, Stringable
    associatedtype Artifact: RGArtifact
    associatedtype CryptoDelegateType: CryptoDelegate
    
    typealias Edge = String
    typealias Path = Artifact.Path
    
    var digest: Digest! { get }
    var artifact: Artifact? { get }
	
    var complete: Bool! { get }
	var targets: TrieSet<Edge>! { get }
	var masks: TrieSet<Edge>! { get }
	var isMasked: Bool! { get }
	var isTargeted: Bool! { get }
    
    init(digest: Digest)
    init(digest: Digest, artifact: Artifact?, complete: Bool)
	init(digest: Digest, artifact: Artifact?, complete: Bool, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool, isTargeted: Bool)
	
	func changing(digest: Digest?, artifact: Artifact?, complete: Bool?, targets: TrieSet<Edge>?, masks: TrieSet<Edge>?, isMasked: Bool?, isTargeted: Bool?) -> Self
    func computedCompleteness() -> Bool
}

public extension Addressable {
	func isComplete() -> Bool {
		return complete
	}
	
	func focused() -> Bool { return !(targets.isEmpty() && masks.isEmpty() && !isMasked && !isTargeted) }
	
	func changing(digest: Digest? = nil, artifact: Artifact? = nil, complete: Bool? = nil, targets: TrieSet<Edge>? = nil, masks: TrieSet<Edge>? = nil, isMasked: Bool? = nil, isTargeted: Bool? = nil) -> Self {
		return Self(digest: digest ?? self.digest, artifact: artifact ?? self.artifact, complete: complete ?? self.complete, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked, isTargeted: isTargeted ?? self.isTargeted)
	}
    
    init?(artifact: Artifact, complete: Bool) {
        guard let artifactHashOutput = CryptoDelegateType.hash(artifact.toBoolArray()) else { return nil }
        guard let digest = Digest(raw: artifactHashOutput) else { return nil }
        self.init(digest: digest, artifact: artifact, complete: complete)
    }
    
    init(digest: Digest) {
        self.init(digest: digest, artifact: nil, complete: true)
    }
    
    init(digest: Digest, artifact: Artifact) {
        self.init(digest: digest, artifact: artifact, complete: artifact.isComplete())
    }
	
	init(digest: Digest, artifact: Artifact?, complete: Bool) {
		self.init(digest: digest, artifact: artifact, complete: complete, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: false, isTargeted: false)
	}

    init?(artifact: Artifact) {
        self.init(artifact: artifact, complete: artifact.isComplete())
    }
    
    init?(raw: [Bool]) {
        guard let data = Data(raw: raw) else { return nil }
        guard let object = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
		self = object
    }
    
    func toBoolArray() -> [Bool] {
        let data = try! JSONEncoder().encode(empty())
        return data.toBoolArray()
    }
    
    func computedCompleteness() -> Bool {
        guard let node = artifact else { return !focused() }
        return node.isComplete()
    }
    
    func contents() -> Mapping<String, [Bool]> {
        guard let node = artifact else { return Mapping<String, [Bool]>() }
		return node.contents().setting(key: digest.toString(), value:
			node.pruning().toBoolArray())
    }
    
	func missing(prefix: Path) -> Mapping<String, [Path]> {
		guard let node = artifact else { return focused() ? Mapping<String, [Path]>().setting(key: digest.toString(), value: [prefix]) : Mapping<String, [Path]>() }
		return node.missing(prefix: prefix)
    }
    
	func capture(digestString: String, content: [Bool], prefix: Path) -> (Self, Mapping<String, [Path]>)? {
		guard let digest = Digest(stringValue: digestString) else { return nil }
        guard let decodedNode = Artifact(raw: content) else { return nil }
        if digest != self.digest { return nil }
		let targetedNode = decodedNode.targeting(targets, prefix: prefix)
		let maskedNode = targetedNode.0.masking(masks, prefix: prefix)
		let shouldMask = maskedNode.0.shouldMask(masks, prefix: prefix)
		let finalNode = (isMasked || shouldMask) ? maskedNode.0.mask(prefix: prefix) : (maskedNode.0, Mapping<String, [Path]>())
		return (changing(artifact: finalNode.0, complete: finalNode.0.isComplete(), targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: (isMasked || shouldMask)), finalNode.0.missing(prefix: prefix))
    }
    
	func capture(digestString: String, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<String, [Path]>)? {
		if route.isEmpty && artifact == nil { return capture(digestString: digestString, content: content, prefix: prefix) }
        guard let node = artifact else { return nil }
		guard let nodeResult = node.capture(digestString: digestString, content: content, at: route, prefix: prefix) else { return nil }
        return (changing(digest: nil, artifact: nodeResult.0, complete: nodeResult.0.isComplete()), nodeResult.1)
    }
    
    func empty() -> Self {
        return Self(digest: digest)
    }
	
	func targeting(_ targets: TrieSet<Edge>, prefix: Path) -> (Self, Mapping<String, [Path]>) {
		if targets.isEmpty() { return (self, Mapping<String, [Path]>()) }
		guard let artifact = artifact else {
			if focused() { return (changing(targets: self.targets.overwrite(with: targets)), Mapping<String, [Path]>()) }
			return (changing(complete: false, targets: self.targets.overwrite(with: targets)), Mapping<String, [Path]>().setting(key: digest.toString(), value: [prefix]))
		}
		let childResult = artifact.targeting(targets, prefix: prefix)
		return (changing(artifact: childResult.0), childResult.1)
	}
	
	func masking(_ masks: TrieSet<Edge>, prefix: Path) -> (Self, Mapping<String, [Path]>) {
		if masks.isEmpty() || isMasked { return (self, Mapping<String, [Path]>()) }
		guard let artifact = artifact else {
			if focused() { return (changing(masks: masks), Mapping<String, [Path]>()) }
			return (changing(complete: false, masks: masks), Mapping<String, [Path]>().setting(key: digest.toString(), value: [prefix]))
		}
		let childResult = artifact.masking(masks, prefix: prefix)
		return (changing(artifact: childResult.0), childResult.1)
	}
	
	func mask(prefix: Path) -> (Self, Mapping<String, [Path]>) {
		if let childResult = artifact?.mask(prefix: prefix) { return (changing(artifact: childResult.0, isMasked: true), childResult.1) }
		if focused() { return (changing(isMasked: true), Mapping<String, [Path]>()) }
		return (changing(complete: false, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: true), Mapping<String, [Path]>().setting(key: digest.toString(), value: [prefix]))
	}
	
	func target(prefix: Path) -> (Self, Mapping<String, [Path]>) {
		return focused() ? (changing(isTargeted: true), Mapping<String, [Path]>()) : (changing(complete: false, isTargeted: true), Mapping<String, [Path]>().setting(key: digest.toString(), value: [prefix]))
	}
}
