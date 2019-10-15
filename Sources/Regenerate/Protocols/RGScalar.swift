import Foundation
import Bedrock
import AwesomeDictionary

// Leaf node
public protocol RGScalar: RGArtifact {
    associatedtype T: Codable
    var scalar: T! { get }
    init(raw: T)
}

public extension RGScalar {
    func isComplete() -> Bool { return true }
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, Mapping<Digest, [Path]>)? { return nil }
    func missing() -> Mapping<Digest, [Path]> { return Mapping<Digest, [Path]>() }
    func contents() -> Mapping<Digest, [Bool]>? { return Mapping<Digest, [Bool]>() }
    func isValid() -> Bool { return true }
}
