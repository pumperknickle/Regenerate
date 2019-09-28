import Foundation
import Bedrock
import TMap

// Leaf node
public protocol RGScalar: RGArtifact {
    associatedtype T: Codable
    var scalar: T! { get }
    init(raw: T)
}

public extension RGScalar {
    func isComplete() -> Bool { return true }
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, TMap<Digest, [Path]>)? { return nil }
    func missing() -> TMap<Digest, [Path]> { return TMap<Digest, [Path]>() }
    func contents() -> TMap<Digest, [Bool]>? { return TMap<Digest, [Bool]>() }
    func isValid() -> Bool { return true }
}
