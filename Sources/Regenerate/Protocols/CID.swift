import Foundation

public protocol CID: Codable {
    associatedtype Artifact: RGArtifact
    typealias CryptoDelegateType = Artifact.CryptoDelegateType
    typealias Digest = Artifact.Digest
    typealias Edge = Artifact.Edge
    typealias Path = Artifact.Path
    
    var digest: Digest! { get }
    var artifact: Artifact? { get }
    var complete: Bool! { get }
    
    init(digest: Digest)
    init(digest: Digest, artifact: Artifact?, complete: Bool)
    func changing(digest: Digest?, artifact: Artifact?, complete: Bool?) -> Self
    
    func missing() -> [Digest: [Path]]
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, [Digest: [Path]])?
    func computedValidity() -> Bool
    func computedCompleteness() -> Bool
    func contents() -> [Digest: [Bool]]?
}

public extension CID {
    func changing(digest: Digest? = nil, artifact: Artifact? = nil, complete: Bool? = nil) -> Self {
        return Self(digest: digest == nil ? self.digest : digest!, artifact: artifact == nil ? self.artifact : artifact!, complete: complete == nil ? self.complete : complete!)
    }
    
    init?(artifact: Artifact, complete: Bool) {
        guard let nodeHash = artifact.hash() else { return nil }
        self.init(digest: nodeHash, artifact: artifact, complete: complete)
    }
    
    init(digest: Digest) {
        self.init(digest: digest, artifact: nil, complete: false)
    }
    
    init(digest: Digest, artifact: Artifact) {
        self.init(digest: digest, artifact: artifact, complete: artifact.isComplete())
    }
    
    init?(artifact: Artifact) {
        self.init(artifact: artifact, complete: artifact.isComplete())
    }
    
    // Imperative integrity verification
    func computedValidity() -> Bool {
        guard let node = artifact else { return true }
        guard let nodeHash = node.hash() else { return false }
        if digest != nodeHash { return false }
        return node.isValid()
    }
    
    func computedCompleteness() -> Bool {
        guard let node = artifact else { return false }
        return node.isComplete()
    }
    
    func contents() -> [Digest: [Bool]]? {
        guard let node = artifact else { return [:] }
        return node.contents()?.setting(digest, withValue: node.toBoolArray())
    }
    
    func missing() -> [Digest: [Path]] {
        guard let node = artifact else { return  [digest: [[]]] }
        return node.missing()
    }
    
    func capture(digest: Digest, content: [Bool]) -> (Self, [Digest: [Path]])? {
        guard let decodedNode = Artifact(raw: content) else { return nil }
        if digest != self.digest { return nil }
        return (changing(digest: nil, artifact: decodedNode, complete: decodedNode.isComplete()), decodedNode.missing())
    }
    
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, [Digest: [Path]])? {
        if route.isEmpty && artifact == nil { return capture(digest: digest, content: content) }
        guard let node = artifact else { return nil }
        guard let nodeResult = node.capture(digest: digest, content: content, at: route) else { return nil }
        return (changing(digest: nil, artifact: nodeResult.0, complete: nodeResult.0.isComplete()), nodeResult.1)
    }
}
