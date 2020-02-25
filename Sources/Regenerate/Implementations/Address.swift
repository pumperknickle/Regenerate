import AwesomeTrie
import Bedrock
import CryptoStarterPack
import Foundation

public struct Address<Artifact: RGArtifact>: Codable {
    private let rawDigest: Digest!
    private let rawArtifact: Artifact?
    private let rawSymmetricKeyHash: Digest?
    private let rawIncomplete: Singleton?
    private let rawTargets: TrieSet<Edge>?
    private let rawMasks: TrieSet<Edge>?
    private let rawIsMasked: Singleton?
    private let rawIsTargeted: Singleton?
    private let rawSymmetricIV: SymmetricIV?

    public init(digest: UInt256, artifact: Artifact?, symmetricKeyHash: Digest?, complete: Bool, targets: TrieSet<Self.Edge>, masks: TrieSet<Self.Edge>, isMasked: Bool, isTargeted: Bool, symmetricIV: UInt128?) {
        rawDigest = digest
        rawArtifact = artifact
        rawSymmetricKeyHash = symmetricKeyHash
        rawIncomplete = complete ? nil : .void
        rawTargets = targets.isEmpty() ? nil : targets
        rawMasks = masks.isEmpty() ? nil : masks
        rawIsMasked = isMasked ? .void : nil
        rawIsTargeted = isTargeted ? .void : nil
        rawSymmetricIV = symmetricIV
    }
}

extension Address: Addressable {
    public typealias CryptoDelegateType = BaseCrypto
    public typealias Digest = UInt256
    public typealias SymmetricDelegateType = BaseSymmetric

    public var digest: Digest! { return rawDigest }
    public var artifact: Artifact? { return rawArtifact }
    public var symmetricKeyHash: Digest? { return rawSymmetricKeyHash }
    public var complete: Bool! { return rawIncomplete != nil ? false : true }
    public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
    public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
    public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
    public var isTargeted: Bool! { return rawIsTargeted != nil ? true : false }
    public var symmetricIV: SymmetricIV? { return rawSymmetricIV }
}
