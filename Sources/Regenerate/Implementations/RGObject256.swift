import Foundation
import CryptoStarterPack

public struct RGObject256<RootType: CID>: Codable where RootType.Digest == UInt256 {
    private let rawRoot: RootType!
    private let rawPaths: [UInt256: [[String]]]!
}

extension RGObject256: RGObject {
    public var root: RootType { return rawRoot }
    public var paths: [RootType.Digest : [Path]] { return rawPaths }
    
    public init(root: RootType, paths: [RootType.Artifact.Digest : [[String]]]) {
        self.rawRoot = root
        self.rawPaths = paths
    }
}
