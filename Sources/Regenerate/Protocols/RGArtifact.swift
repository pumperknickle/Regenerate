import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGArtifact: Codable, BinaryEncodable {
    associatedtype Digest: FixedWidthInteger, Stringable
    
    typealias Edge = String
    typealias Path = [Edge]
    
    func isComplete() -> Bool
	func capture(digest: Digest, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<Digest, [Path]>)?
    func missing(prefix: Path) -> Mapping<Digest, [Path]>
    func contents() -> Mapping<Digest, [Bool]>?
    func pruning() -> Self
	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>)
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>)
	func mask(prefix: [Edge]) -> (Self, Mapping<Digest, [Path]>)
	func shouldMask(_ masks: TrieSet<Edge>, prefix: [Edge]) -> Bool
}

public extension RGArtifact {
    init?(raw: [Bool]) {
        guard let data = Data(raw: raw) else { return nil }
        guard let node = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = node
    }
    
    func toBoolArray() -> [Bool] {
        return try! JSONEncoder().encode(pruning()).toBoolArray()
    }
	
	func shouldMask(_ masks: TrieSet<Edge>, prefix: [Edge]) -> Bool {
		return false
	}
}
