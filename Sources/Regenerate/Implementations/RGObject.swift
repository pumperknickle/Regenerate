import AwesomeDictionary
import Bedrock
import Foundation

public struct RGObject<RootType: Addressable> where RootType.Digest == UInt256 {
    public typealias Path = RootType.Path
    private let rawRoot: RootType!
    private let rawPaths: Mapping<RootType.Digest, [Path]>!
}

extension RGObject: Regenerative {
    public var root: RootType { return rawRoot }
    public var keyPaths: Mapping<RootType.Digest, [Path]> { return rawPaths }

    public init(root: RootType, paths: Mapping<RootType.Digest, [Path]>) {
        rawRoot = root
        rawPaths = paths
    }
}

extension RGObject: Codable {
    enum CodingKeys: String, CodingKey {
        case root
        case paths
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rawRoot = try values.decode(RootType.self, forKey: .root)
        rawPaths = try values.decode(Mapping<RootType.Digest, [Path]>.self, forKey: .paths)
        return
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawRoot, forKey: .root)
        try container.encode(rawPaths, forKey: .paths)
        return
    }
}
