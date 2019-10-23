import Foundation
import Bedrock
import CryptoStarterPack
import AwesomeTrie

public struct Stem256: Codable {
    private let rawDigest: UInt256!
    private let rawArtifact: Radix256?
    private let rawIncomplete: Singleton?
	private let rawTargets: TrieSet<Edge>?
	private let rawMasks: TrieSet<Edge>?
	private let rawIsMasked: Singleton?
	private let rawIsTargeted: Singleton?
}

extension Stem256: CID {
	public var digest: UInt256! { return rawDigest }
    public var artifact: Radix256? { return rawArtifact }
	public var complete: Bool! { return rawIncomplete != nil ? false : true }
	public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
	public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
	public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
	public var isTargeted: Bool! { return rawIsTargeted != nil ? true : false }
	
    public typealias CryptoDelegateType = BaseCrypto
	
	public init(digest: Artifact.Digest, artifact: Artifact?, complete: Bool, targets: TrieSet<Self.Edge>, masks: TrieSet<Self.Edge>, isMasked: Bool, isTargeted: Bool) {
		rawDigest = digest
		rawArtifact = artifact
		rawIncomplete = complete ? nil : .void
		rawTargets = targets.isEmpty() ? nil : targets
		rawMasks = masks.isEmpty() ? nil : masks
		rawIsMasked = isMasked ? .void : nil
		rawIsTargeted = isTargeted ? .void : nil
	}
}

extension Stem256: Stem {
    public typealias Artifact = Radix256
}
