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
    public init(from decoder: Decoder) throws {
        rawRoot = RootType(raw: [true])
        rawPaths = Mapping<RootType.Digest, [Path]>()
        return
    }
    
    public func encode(to encoder: Encoder) throws {
        return
    }
}
