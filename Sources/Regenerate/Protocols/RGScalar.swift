import AwesomeDictionary
import AwesomeTrie
import Bedrock
import Foundation

// Leaf node
public protocol RGScalar: RGArtifact {
    associatedtype T: DataEncodable
    var scalar: T! { get }
    init(scalar: T)
}

public extension RGScalar {
    func isComplete() -> Bool { return true }
    func capture(digestString _: String, content _: Data, at _: Path, prefix _: Path) -> (Self, Mapping<Data, [Path]>)? { return nil }
    func missing(prefix _: Path) -> Mapping<Data, [Path]> { return Mapping<Data, [Path]>() }
    func contents(prefix _: Path) -> Mapping<Data, Data> { return Mapping<Data, Data>() }
    func isValid() -> Bool { return true }
    func targeting(_: TrieSet<Edge>, prefix _: [Edge]) -> (Self, Mapping<Data, [Path]>) { return (self, Mapping<Data, [Path]>()) }
    func masking(_: TrieSet<Edge>, prefix _: [Edge]) -> (Self, Mapping<Data, [Path]>) { return (self, Mapping<Data, [Path]>()) }
    func mask(prefix _: [Edge]) -> (Self, Mapping<Data, [Path]>) { (self, Mapping<Data, [Path]>()) }
    func set(property _: String, to _: CryptoBindable) -> Self? { return nil }
    func get(property _: String) -> CryptoBindable? { return nil }
    static func properties() -> [String] { return [] }
    func pruning() -> Self { return self }
    func encrypt(allKeys _: CoveredTrie<String, Data>, commonIv _: Data) -> Self? { return self }
    func toData() -> Data { return scalar.toData() }
    init?(data: Data) {
        guard let scalar = T(data: data) else { return nil }
        self = Self(scalar: scalar)
    }
}
