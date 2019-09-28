import Foundation
import Bedrock
import CryptoStarterPack
import TMap

public protocol CID: Codable, BinaryEncodable {
    associatedtype Artifact: RGArtifact
    associatedtype CryptoDelegateType: CryptoDelegate
    
    typealias Digest = Artifact.Digest
    typealias Edge = Artifact.Edge
    typealias Path = Artifact.Path
    
    var digest: Digest! { get }
    var artifact: Artifact? { get }
    var complete: Bool! { get }
    
    init(digest: Digest)
    init(digest: Digest, artifact: Artifact?, complete: Bool)
    func changing(digest: Digest?, artifact: Artifact?, complete: Bool?) -> Self
    
    func missing() -> TMap<Digest, [Path]>
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, TMap<Digest, [Path]>)?
    func computedCompleteness() -> Bool
    func contents() -> TMap<Digest, [Bool]>?
}

public extension CID {
    func changing(digest: Digest? = nil, artifact: Artifact? = nil, complete: Bool? = nil) -> Self {
        return Self(digest: digest == nil ? self.digest : digest!, artifact: artifact == nil ? self.artifact : artifact!, complete: complete == nil ? self.complete : complete!)
    }
    
    init?(artifact: Artifact, complete: Bool) {
        guard let artifactHashOutput = CryptoDelegateType.hash(artifact.toBoolArray()) else { return nil }
        guard let digest = Digest(raw: artifactHashOutput) else { return nil }
        self.init(digest: digest, artifact: artifact, complete: complete)
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
    
    init?(raw: [Bool]) {
        guard let data = Data(raw: raw) else { return nil }
        guard let object = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = object
    }
    
    func toBoolArray() -> [Bool] {
        let data = try! JSONEncoder().encode(empty())
        return data.toBoolArray()
    }
    
    func computedCompleteness() -> Bool {
        guard let node = artifact else { return false }
        return node.isComplete()
    }
    
    func contents() -> TMap<Digest, [Bool]>? {
        guard let node = artifact else { return TMap<Digest, [Bool]>() }
        return node.contents()?.setting(key: digest, value: node.toBoolArray())
    }
    
    func missing() -> TMap<Digest, [Path]> {
        guard let node = artifact else { return  TMap<Digest, [Path]>().setting(key: digest, value: [[]]) }
        return node.missing()
    }
    
    func capture(digest: Digest, content: [Bool]) -> (Self, TMap<Digest, [Path]>)? {
        guard let decodedNode = Artifact(raw: content) else { return nil }
        if digest != self.digest { return nil }
        return (changing(digest: nil, artifact: decodedNode, complete: decodedNode.isComplete()), decodedNode.missing())
    }
    
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, TMap<Digest, [Path]>)? {
        if route.isEmpty && artifact == nil { return capture(digest: digest, content: content) }
        guard let node = artifact else { return nil }
        guard let nodeResult = node.capture(digest: digest, content: content, at: route) else { return nil }
        return (changing(digest: nil, artifact: nodeResult.0, complete: nodeResult.0.isComplete()), nodeResult.1)
    }
    
    func empty() -> Self {
        return Self(digest: digest)
    }
}
