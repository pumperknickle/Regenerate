import Foundation
import CryptoStarterPack

public struct Stem256: Codable {
    private let rawDigest: UInt256!
    private let rawArtifact: Radix256?
    private let rawComplete: Bool!
}

extension Stem256: CID {
    public typealias CryptoDelegateType = BaseCrypto
    
    public init(digest: UInt256, artifact: Radix256?, complete: Bool) {
        self.rawDigest = digest
        self.rawArtifact = artifact
        self.rawComplete = complete
    }
    
    public var digest: UInt256! { return rawDigest }
    
    public var artifact: Radix256? { return rawArtifact }
    
    public var complete: Bool! { return rawComplete }
}

extension Stem256: Stem {
    public typealias Artifact = Radix256
}
