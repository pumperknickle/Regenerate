import Foundation
import CryptoStarterPack

public struct StemOverlay256: Codable {
    private let rawDigest: UInt256!
    private let rawArtifact: RadixOverlay256?
    private let rawComplete: Bool!
    private let rawTargets: [[Symbol]]?
    private let rawMasks: [[Symbol]]?
    private let rawIsMasked: Bool!
}

extension StemOverlay256: CID {
    public typealias CryptoDelegateType = BaseCrypto

    public init(digest: UInt256, artifact: RadixOverlay256?, complete: Bool) {
        self.rawDigest = digest
        self.rawArtifact = artifact
        self.rawComplete = complete
        self.rawTargets = nil
        self.rawMasks  = nil
        self.rawIsMasked = false
    }
    
    public typealias Artifact = RadixOverlay256
    
    public var digest: UInt256! { return rawDigest }
    public var artifact: RadixOverlay256? { return rawArtifact }
    public var complete: Bool! { return rawComplete }
    
}

extension StemOverlay256: Stem {
    
}

extension StemOverlay256: StemOverlay {
    public init(digest: UInt256, artifact: RadixOverlay256?, complete: Bool, targets: [[Symbol]]?, masks: [[Symbol]]?, isMasked: Bool) {
        self.rawDigest = digest
        self.rawArtifact = artifact
        self.rawComplete = complete
        self.rawTargets = targets
        self.rawMasks = masks
        self.rawIsMasked = isMasked
    }
    
    public var targets: [[Symbol]]? { return rawTargets }
    
    public var masks: [[Symbol]]? { return rawMasks }
    
    public var isMasked: Bool! { return rawIsMasked }
}
