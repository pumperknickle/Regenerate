import Foundation
import Bedrock
import AwesomeDictionary

public struct RGObject256<RootType: CID>: Codable where RootType.Digest == UInt256 {
    private let rawRoot: RootType!
    private let rawPaths: Mapping<RootType.Digest, [Path]>!
}

extension RGObject256: RGObject {
    public var root: RootType { return rawRoot }
    public var keyPaths: Mapping<RootType.Digest, [Path]> { return rawPaths }
    
    public init(root: RootType, paths: Mapping<RootType.Digest, [Path]>) {
        self.rawRoot = root
        self.rawPaths = paths
    }
}
