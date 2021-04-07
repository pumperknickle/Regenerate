import AwesomeTrie
import Bedrock
import CryptoStarterPack
import Foundation
import AwesomeDictionary

public struct Address<Artifact: RGArtifact> {
    private let rawFingerprint: Digest!
    private let rawDataItem: Artifact?
    private let rawFingerprintOfSymmetricKey: Digest?
    private let rawIncomplete: Singleton?
    private let rawTargets: TrieSet<Edge>?
    private let rawMasks: TrieSet<Edge>?
    private let rawIsMasked: Singleton?
    private let rawIsTargeted: Singleton?
    private let rawSymmetricIV: SymmetricIV?

    public init(fingerprint: UInt256, dataItem: Artifact?, fingerprintOfSymmetricKey: Digest?, complete: Bool, targets: TrieSet<Self.Edge>, masks: TrieSet<Self.Edge>, isMasked: Bool, isTargeted: Bool, symmetricIV: UInt128?) {
        rawFingerprint = fingerprint
        rawDataItem = dataItem
        rawFingerprintOfSymmetricKey = fingerprintOfSymmetricKey
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

    public var fingerprint: Digest! { return rawFingerprint }
    public var dataItem: Artifact? { return rawDataItem }
    public var fingerprintOfSymmetricKey: Digest? { return rawFingerprintOfSymmetricKey }
    public var complete: Bool! { return rawIncomplete != nil ? false : true }
    public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
    public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
    public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
    public var isTargeted: Bool! { return rawIsTargeted != nil ? true : false }
    public var symmetricIV: SymmetricIV? { return rawSymmetricIV }
}

extension Address: Codable {
    private enum CodingKeys: String, CodingKey {
        case fingerprint
        case dataItem
        case fingerprintOfSymmetricKey
        case incomplete
        case targets
        case masks
        case isMasked
        case isTargeted
        case symmetricIV
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawFingerprint = try values.decode(Digest.self, forKey: .fingerprint)
        let rawDataItem = try? values.decode(Artifact.self, forKey: .dataItem)
        let rawFingerprintOfSymmetricKey = try? values.decode(Digest.self, forKey: .fingerprintOfSymmetricKey)
        let rawIncomplete = try? values.decode(Singleton.self, forKey: .incomplete)
        let rawTargets = try? values.decode(TrieSet<Edge>.self, forKey: .targets)
        let rawMasks = try? values.decode(TrieSet<Edge>.self, forKey: .masks)
        let rawIsMasked = try? values.decode(Singleton.self, forKey: .isMasked)
        let rawIsTargeted = try? values.decode(Singleton.self, forKey: .isTargeted)
        let rawSymmetricIV = try? values.decode(SymmetricIV.self, forKey: .symmetricIV)
        self.init(fingerprint: rawFingerprint, dataItem: rawDataItem, fingerprintOfSymmetricKey: rawFingerprintOfSymmetricKey, complete: rawIncomplete != nil ? false : true, targets: rawTargets ?? TrieSet<Edge>(), masks: rawMasks ?? TrieSet<Edge>(), isMasked: rawIsMasked != nil ? true : false, isTargeted: rawIsTargeted != nil ? true : false, symmetricIV: rawSymmetricIV)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawFingerprint, forKey: .fingerprint)
        try container.encodeIfPresent(rawDataItem, forKey: .dataItem)
        try container.encodeIfPresent(rawFingerprintOfSymmetricKey, forKey: .fingerprintOfSymmetricKey)
        try container.encodeIfPresent(rawIncomplete, forKey: .incomplete)
        try container.encodeIfPresent(rawTargets, forKey: .targets)
        try container.encodeIfPresent(rawMasks, forKey: .masks)
        try container.encodeIfPresent(rawIsMasked, forKey: .isMasked)
        try container.encodeIfPresent(rawIsTargeted, forKey: .isTargeted)
        try container.encodeIfPresent(rawSymmetricIV, forKey: .symmetricIV)
        return
    }
}
