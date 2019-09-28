import Foundation
import Bedrock
import TMap

public protocol RGArtifact: Codable, BinaryEncodable {
    associatedtype Digest: FixedWidthInteger, Stringable
    
    typealias Edge = String
    typealias Path = [Edge]
    
    func isComplete() -> Bool
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, TMap<Digest, [Path]>)?
    func missing() -> TMap<Digest, [Path]>
    func contents() -> TMap<Digest, [Bool]>?
    func pruning() -> Self
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
}
