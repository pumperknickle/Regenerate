import AwesomeDictionary
import Bedrock
import Foundation

public struct RT256<Key: DataEncodable, Value: DataEncodable> {
    private let rawRoot: Root!
    private let rawPaths: Mapping<Digest, [Path]>!
}

extension RT256: Discoverable {
    public typealias Root = RadixAddress256

    public var root: Root { return rawRoot }
    public var keyPaths: Mapping<Digest, [Path]> { return rawPaths }

    public init(root: Root, paths: Mapping<Digest, [Path]>) {
        rawRoot = root
        rawPaths = paths
    }
}

extension RT256: RGRT {
    public func decodeKey(symbols: [String]) -> Data? { return Data(hexString: symbols.reduce("", +)) }
    public func encodeKey(key: Data) -> [String]? { return key.toHexString().map { "\($0)" } }
    public func decodeValue(symbols: [String]) -> Data? { return Data(hexString: symbols.reduce("", +)) }
    public func encodeValue(value: Data) -> [String]? { return value.toHexString().map { "\($0)" } }
}

extension RT256: Codable {
    private enum CodingKeys: String, CodingKey {
        case root
        case paths
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawRoot = try values.decode(Root.self, forKey: .root)
        let rawPaths = try values.decode(Mapping<Digest, [Path]>.self, forKey: .root)
        self.init(root: rawRoot, paths: rawPaths)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawRoot, forKey: .root)
        try container.encode(rawPaths, forKey: .paths)
        return
    }
}
