import Foundation

public struct RGCID<Artifact: RGArtifact>: Codable {
    private let rawDigest: Artifact.Digest!
    private let rawArtifact: Artifact?
    private let rawComplete: Bool!
}

extension RGCID: CID {
    public var digest: Artifact.Digest! { return rawDigest }
    public var artifact: Artifact? { return rawArtifact }
    public var complete: Bool! { return rawComplete }
    
    public init(digest: Artifact.Digest, artifact: Artifact?, complete: Bool) {
        self.rawDigest = digest
        self.rawArtifact = artifact
        self.rawComplete = complete
    }
}
