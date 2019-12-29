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
	func capture(digestString: String, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<String, [Path]>)? { return nil }
	func missing(prefix: Path) -> Mapping<String, [Path]> { return Mapping<String, [Path]>() }
	func contents(prefix: Path) -> Mapping<String, [Bool]> { return Mapping<String, [Bool]>() }
    func isValid() -> Bool { return true }
	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { return (self, Mapping<String, [Path]>()) }
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { return (self, Mapping<String, [Path]>()) }
	func mask(prefix: [Edge]) -> (Self, Mapping<String, [Path]>) { (self, Mapping<String, [Path]>()) }
	func set(property: String, to child: CryptoBindable) -> Self? { return nil }
	func get(property: String) -> CryptoBindable? { return nil }
	static func properties() -> [String] { return [] }
	func pruning() -> Self { return self }
	func encrypt(allKeys: CoveredTrie<String, [Bool]>, commonIv: [Bool]) -> Self? { return self }
}

public extension RGScalar where T == String {
    func toBoolArray() -> [Bool] {
        return scalar.toBoolArray()
    }
    
    init?(raw: [Bool]) {
        guard let stringValue = String(raw: raw) else { return nil }
        self = Self(scalar: stringValue)
    }
}

public extension RGScalar where T == [Bool] {
    func toBoolArray() -> [Bool] {
        return scalar
    }
    
    init?(raw: [Bool]) {
        self = Self(scalar: raw)
    }
}

public extension RGScalar where T == Data {
    func toBoolArray() -> [Bool] {
        return scalar.toBoolArray()
    }
    
    init?(raw: [Bool]) {
        guard let dataValue = Data(raw: raw) else { return nil }
        self = Self(scalar: dataValue)
    }
}
