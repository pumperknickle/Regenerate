import Foundation
import Bedrock
import AwesomeDictionary

public struct RGObject<RootType: Addressable>: Codable where RootType.Digest == UInt256 {
    private let rawRoot: RootType!
    private let rawPaths: Mapping<Data, [Path]>!
}

extension RGObject: Regenerative {
    public var root: RootType { return rawRoot }
    public var keyPaths: Mapping<Data, [Path]> { return rawPaths }

    public init(root: RootType, paths: Mapping<Data, [Path]>) {
        self.rawRoot = root
        self.rawPaths = paths
    }
}
