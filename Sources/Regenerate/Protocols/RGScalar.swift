import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

// Leaf node
public protocol RGScalar: RGArtifact {
    associatedtype T: Codable
    var scalar: T! { get }
    init(scalar: T)
}

public extension RGScalar {
    func isComplete() -> Bool { return true }
    func capture(digestString: String, content: Data, at route: Path, prefix: Path) -> (Self, Mapping<String, [Path]>)? { return nil }
	func missing(prefix: Path) -> Mapping<String, [Path]> { return Mapping<String, [Path]>() }
    func contents(prefix: Path) -> Mapping<String, Data> { return Mapping<String, Data>() }
    func isValid() -> Bool { return true }
	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { return (self, Mapping<String, [Path]>()) }
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { return (self, Mapping<String, [Path]>()) }
	func mask(prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { (self, Mapping<String, [Path]>()) }
	func set(property: String, to child: CryptoBindable) -> Self? { return nil }
	func get(property: String) -> CryptoBindable? { return nil }
	static func properties() -> [String] { return [] }
	func pruning() -> Self { return self }
    func encrypt(allKeys: CoveredTrie<String, Data>, commonIv: Data) -> Self? { return self }
}

public extension RGScalar where T == String {
    func toData() -> Data {
        return scalar.toData()
    }
    
    init?(data: Data) {
        guard let stringValue = String(data: data) else { return nil }
        self = Self(scalar: stringValue)
    }
}

public extension RGScalar where T == Data {
    func toData() -> Data {
        return scalar
    }
    
    init?(data: Data) {
        self = Self(scalar: data)
    }
}
