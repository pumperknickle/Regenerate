import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

// Leaf node
public protocol RGScalar: RGArtifact {
    associatedtype T: Codable
    var scalar: T! { get }
    init(raw: T)
}

public extension RGScalar {
    func isComplete() -> Bool { return true }
	func capture(digestString: String, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<String, [Path]>)? { return nil }
	func missing(prefix: Path) -> Mapping<String, [Path]> { return Mapping<String, [Path]>() }
    func contents() -> Mapping<String, [Bool]> { return Mapping<String, [Bool]>() }
    func isValid() -> Bool { return true }
	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { return (self, Mapping<String, [Path]>()) }
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { return (self, Mapping<String, [Path]>()) }
	func mask(prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { (self, Mapping<String, [Path]>()) }
	func set(property: String, to child: CryptoBindable) -> Self? { return nil }
	func get(property: String) -> CryptoBindable? { return nil }
	func properties() -> [String] { return [] }
	func pruning() -> Self { return self }
	func set(key: [Bool]) -> Self? { return self }
}
