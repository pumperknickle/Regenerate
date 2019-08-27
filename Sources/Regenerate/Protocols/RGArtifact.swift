import Foundation
import CryptoStarterPack

public protocol RGArtifact: Codable, CryptoHashable {
    associatedtype CryptoDelegateType: CryptoDelegate
    typealias Edge = String
    typealias Path = [Edge]
    
    init?(content: Data)
    
    func isValid() -> Bool
    func isComplete() -> Bool
    func serialize() -> Data?
    func capture(digest: Digest, content: Data, at route: Path) -> (Self, [Digest: [Path]])?
    func missing() -> [Digest: [Path]]
    func contents() -> [Digest: Data]?
    func pruning() -> Self
}

public extension RGArtifact {
    func hash() -> Digest? {
        guard let serializedPrunedNode = serialize() else { return nil }
        guard let hashedBits = CryptoDelegateType.hash(serializedPrunedNode) else { return nil }
        return Digest(raw: hashedBits)
    }
    
    func serialize() -> Data? {
        return try? JSONEncoder().encode(pruning())
    }
    
    init?(content: Data) {
        guard let node = try? JSONDecoder().decode(Self.self, from: content) else { return nil }
        self = node
    }
}
