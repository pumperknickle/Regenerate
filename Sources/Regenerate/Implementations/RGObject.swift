import AwesomeDictionary
import Bedrock
import Foundation

public struct RGObject<RootType: Addressable>: Codable where RootType.Digest == UInt256 {
    private let rawRoot: RootType!
    private let rawPaths: Mapping<Data, [Path]>!
}

extension RGObject: Regenerative {
    public var root: RootType { return rawRoot }
    public var keyPaths: Mapping<Data, [Path]> { return rawPaths }

    public init(root: RootType, paths: Mapping<Data, [Path]>) {
        rawRoot = root
        rawPaths = paths
    }
}
