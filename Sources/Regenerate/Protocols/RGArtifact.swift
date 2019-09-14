import Foundation
import CryptoStarterPack

public protocol RGArtifact: Codable, CryptoHashable, BinaryEncodable {
    associatedtype CryptoDelegateType: CryptoDelegate
    typealias Edge = String
    typealias Path = [Edge]
    
    func isValid() -> Bool
    func isComplete() -> Bool
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, [Digest: [Path]])?
    func missing() -> [Digest: [Path]]
    func contents() -> [Digest: [Bool]]?
    func pruning() -> Self
}

public extension RGArtifact {
    func hash() -> Digest? {
        guard let hashedBits = CryptoDelegateType.hash(toBoolArray()) else { return nil }
        return Digest(raw: hashedBits)
    }
    
    init?(raw: [Bool]) {
        guard let data = Data(raw: raw) else { return nil }
        guard let node = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = node
    }
    
    func toBoolArray() -> [Bool] {
        return try! JSONEncoder().encode(pruning()).toBoolArray()
    }
}
