import Foundation
import Bedrock
import CryptoStarterPack
import AwesomeTrie

public struct Address<Artifact: RGArtifact>: Codable {
    private let rawDigest: Digest!
    private let rawArtifact: Artifact?
	private let rawSymmetricKey: SymmetricKey?
    private let rawIncomplete: Singleton?
	private let rawTargets: TrieSet<Edge>?
	private let rawMasks: TrieSet<Edge>?
	private let rawIsMasked: Singleton?
	private let rawIsTargeted: Singleton?
}

extension Address: Addressable {
	public typealias SymmetricDelegateType = BaseSymmetric
	public typealias CryptoDelegateType = BaseCrypto
	public typealias Digest = UInt256
	public typealias SymmetricKey = SymmetricDelegateType.Key

    public var digest: Digest! { return rawDigest }
    public var artifact: Artifact? { return rawArtifact }
	public var symmetricKey: SymmetricKey? { return rawSymmetricKey }
	public var complete: Bool! { return rawIncomplete != nil ? false : true }
	public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
	public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
	public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
	public var isTargeted: Bool! { return rawIsTargeted != nil ? true : false }
	
	public init(digest: Digest, artifact: Artifact?, symmetricKey: SymmetricKey?, complete: Bool, targets: TrieSet<Self.Edge>, masks: TrieSet<Self.Edge>, isMasked: Bool, isTargeted: Bool) {
		rawDigest = digest
		rawArtifact = artifact
		rawSymmetricKey = symmetricKey
		rawIncomplete = complete ? nil : .void
		rawTargets = targets.isEmpty() ? nil : targets
		rawMasks = masks.isEmpty() ? nil : masks
		rawIsMasked = isMasked ? .void : nil
		rawIsTargeted = isTargeted ? .void : nil
	}
}
