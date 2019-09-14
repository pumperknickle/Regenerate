import Foundation

// Leaf node
public protocol RGScalar: RGArtifact {
    associatedtype T: Codable
    var scalar: T! { get }
    init(raw: T)
}

public extension RGScalar {
    func isComplete() -> Bool { return true }
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, [Digest: [Path]])? { return nil }
    func missing() -> [Digest : [Path]] { return [:] }
    func contents() -> [Digest : [Bool]]? { return [:] }
    func isValid() -> Bool { return true }
}
