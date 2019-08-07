import Foundation
import CryptoStarterPack

public struct StemOverlay256: Codable {
    private let rawDigest: UInt256!
    private let rawArtifact: RadixOverlay256?
    private let rawComplete: Bool!
    private let rawTargets: [[Bool]]?
    private let rawMasks: [[Bool]]?
    private let rawIsMasked: Bool!
}

extension StemOverlay256: CID {
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
    public init(digest: UInt256, artifact: RadixOverlay256?, complete: Bool, targets: [[Bool]]?, masks: [[Bool]]?, isMasked: Bool) {
        self.rawDigest = digest
        self.rawArtifact = artifact
        self.rawComplete = complete
        self.rawTargets = targets
        self.rawMasks = masks
        self.rawIsMasked = isMasked
    }
    
    public var targets: [[Bool]]? { return rawTargets }
    
    public var masks: [[Bool]]? { return rawMasks }
    
    public var isMasked: Bool! { return rawIsMasked }
}
