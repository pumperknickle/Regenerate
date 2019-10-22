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
	func capture(digest: Digest, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<Digest, [Path]>)? { return nil }
	func missing(prefix: Path) -> Mapping<Digest, [Path]> { return Mapping<Digest, [Path]>() }
    func contents() -> Mapping<Digest, [Bool]>? { return Mapping<Digest, [Bool]>() }
    func isValid() -> Bool { return true }
	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>) { return (self, Mapping<Digest, [Path]>()) }
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>) { return (self, Mapping<Digest, [Path]>()) }
	func mask(prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>) { (self, Mapping<Digest, [Path]>()) }
}
