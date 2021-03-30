import AwesomeDictionary
import AwesomeTrie
import Bedrock
import CryptoStarterPack
import Foundation

public protocol Addressable: CryptoBindable, DataEncodable {
    associatedtype Digest: Stringable
    associatedtype Artifact: RGArtifact
    associatedtype CryptoDelegateType: CryptoDelegate
    associatedtype SymmetricDelegateType: SymmetricDelegate

    typealias Edge = String
    typealias Path = Artifact.Path
    typealias SymmetricKey = SymmetricDelegateType.Key
    typealias SymmetricIV = SymmetricDelegateType.IV
    
    // unique fingerprint with the hash influenced by this data item, all subnodes, encrypted and non-encrypted and all corresponding IV.
    var fingerprint: Digest! { get }
    var dataItem: Artifact? { get }
    var fingerprintOfSymmetricKey: Digest? { get }
    var symmetricIV: SymmetricIV? { get }
    // all *requested* content has been retrieved at this node and subnodes.
    var complete: Bool! { get }
    // paths to all query-target children
    var targets: TrieSet<Edge>! { get }
    // paths to all query-mask children
    var masks: TrieSet<Edge>! { get }
    // if true, for all subnodes isMasked == true
    var isMasked: Bool! { get }
    var isTargeted: Bool! { get }

    init(fingerprint: Digest, fingerprintOfSymmetricKey: Digest?, symmetricIV: SymmetricIV?)
    init(fingerprint: Digest, dataItem: Artifact?, fingerprintOfSymmetricKey: Digest?, symmetricIV: SymmetricIV?, complete: Bool)
    init(fingerprint: Digest, dataItem: Artifact?, fingerprintOfSymmetricKey: Digest?, complete: Bool, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool, isTargeted: Bool, symmetricIV: SymmetricIV?)

    func changing(fingerprint: Digest?, dataItem: Artifact?, complete: Bool?, targets: TrieSet<Edge>?, masks: TrieSet<Edge>?, isMasked: Bool?, isTargeted: Bool?) -> Self
    func computedCompleteness() -> Bool
}

public extension Addressable {
    func encrypt(allKeys: CoveredTrie<String, Data>, keyRoot: Bool) -> Self? {
        guard let artifact = dataItem else { return nil }
        guard let encryptedArtifact = artifact.encrypt(allKeys: allKeys) else { return nil }
        guard let symmetricKeyData = allKeys.cover else { return changing(dataItem: encryptedArtifact) }
        guard let symmetricKey = SymmetricKey(data: Data(symmetricKeyData)) else { return nil }
        let IV = SymmetricIV.random()
        guard let ciphertext = SymmetricDelegateType.encrypt(plaintext: encryptedArtifact.pruning(), key: symmetricKey, iv: IV) else { return nil }
        guard let ciphertextHashOutput = CryptoDelegateType.hash(ciphertext) else { return nil }
        guard let ciphertextDigest = Digest(data: ciphertextHashOutput) else { return nil }
        if !keyRoot { return Self(fingerprint: ciphertextDigest, dataItem: encryptedArtifact, fingerprintOfSymmetricKey: nil, complete: complete, targets: targets, masks: masks, isMasked: isMasked, isTargeted: isTargeted, symmetricIV: IV) }
        guard let symmetricKeyHashData = BaseCrypto.hash(symmetricKeyData) else { return nil }
        guard let symmetricKeyHash = Digest(data: symmetricKeyHashData) else { return nil }
        return Self(fingerprint: ciphertextDigest, dataItem: encryptedArtifact, fingerprintOfSymmetricKey: symmetricKeyHash, complete: complete, targets: targets, masks: masks, isMasked: isMasked, isTargeted: isTargeted, symmetricIV: IV)
    }

    func isComplete() -> Bool {
        return complete
    }

    func focused() -> Bool { return !(targets.isEmpty() && masks.isEmpty() && !isMasked && !isTargeted) }

    func changing(fingerprint: Digest? = nil, dataItem: Artifact? = nil, complete: Bool? = nil, targets: TrieSet<Edge>? = nil, masks: TrieSet<Edge>? = nil, isMasked: Bool? = nil, isTargeted: Bool? = nil) -> Self {
        return Self(fingerprint: fingerprint ?? self.fingerprint, dataItem: dataItem ?? self.dataItem, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, complete: complete ?? self.complete, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked, isTargeted: isTargeted ?? self.isTargeted, symmetricIV: symmetricIV)
    }

    init?(dataItem: Artifact, fingerprintOfSymmetricKey: Digest? = nil, symmetricIV: SymmetricIV? = nil, complete: Bool) {
        let nodeData = dataItem.pruning().toData()
        guard let artifactHashOutput = CryptoDelegateType.hash(nodeData) else { return nil }
        guard let digest = Digest(data: artifactHashOutput) else { return nil }
        self.init(fingerprint: digest, dataItem: dataItem, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, symmetricIV: symmetricIV, complete: complete)
    }

    init(fingerprint: Digest, fingerprintOfSymmetricKey: Digest? = nil, symmetricIV: SymmetricIV? = nil) {
        self.init(fingerprint: fingerprint, dataItem: nil, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, symmetricIV: symmetricIV, complete: true)
    }

    init(fingerprint: Digest, dataItem: Artifact, fingerprintOfSymmetricKey: Digest?, symmetricIV: SymmetricIV?) {
        self.init(fingerprint: fingerprint, dataItem: dataItem, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, symmetricIV: symmetricIV, complete: dataItem.isComplete())
    }

    init(fingerprint: Digest, dataItem: Artifact?, fingerprintOfSymmetricKey: Digest?, symmetricIV: SymmetricIV?, complete: Bool) {
        self.init(fingerprint: fingerprint, dataItem: dataItem, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, complete: complete, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: false, isTargeted: false, symmetricIV: symmetricIV)
    }

    init?(dataItem: Artifact, fingerprintOfSymmetricKey: Digest?, symmetricIV: SymmetricIV?) {
        self.init(dataItem: dataItem, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, symmetricIV: symmetricIV, complete: dataItem.isComplete())
    }

    func toData() -> Data {
        return try! JSONEncoder().encode(empty())
    }

    init?(data: Data) {
        guard let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = decoded
    }

    func computedCompleteness() -> Bool {
        guard let node = dataItem else { return !focused() }
        return node.isComplete()
    }

    func contents(previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> Mapping<Data, Data> {
        guard let node = dataItem else { return Mapping<Data, Data>() }
        guard let symmetricKeyHash = fingerprintOfSymmetricKey else {
            guard let previousKey = previousKey else { return node.contents(previousKey: nil, keys: keys).setting(key: fingerprint.toData(), value: node.pruning().toData()) }
            guard let symmetricKey = SymmetricKey(data: previousKey) else { return Mapping<Data, Data>() }
            guard let IV = symmetricIV else { return Mapping<Data, Data>() }
            guard let ciphertext = SymmetricDelegateType.encrypt(plaintext: node.pruning(), key: symmetricKey, iv: IV) else { return Mapping<Data, Data>() }
            guard let ciphertextHashOutput = CryptoDelegateType.hash(ciphertext) else { return Mapping<Data, Data>() }
            guard let ciphertextDigest = Digest(data: ciphertextHashOutput) else { return Mapping<Data, Data>() }
            return node.contents(previousKey: previousKey, keys: keys).setting(key: ciphertextDigest.toData(), value: ciphertext)
        }
        guard let symmetricKeyData = keys[symmetricKeyHash.toData()] else { return Mapping<Data, Data>() }
        guard let symmetricKey = SymmetricKey(data: symmetricKeyData) else { return Mapping<Data, Data>() }
        guard let IV = symmetricIV else { return Mapping<Data, Data>() }
        guard let ciphertext = SymmetricDelegateType.encrypt(plaintext: node.pruning(), key: symmetricKey, iv: IV) else { return Mapping<Data, Data>() }
        guard let ciphertextHashOutput = CryptoDelegateType.hash(ciphertext) else { return Mapping<Data, Data>() }
        guard let ciphertextDigest = Digest(data: ciphertextHashOutput) else { return Mapping<Data, Data>() }
        return node.contents(previousKey: symmetricKeyData, keys: keys).setting(key: ciphertextDigest.toData(), value: ciphertext)
    }

    func missing(prefix: Path) -> Mapping<Data, [Path]> {
        guard let node = dataItem else { return focused() ? Mapping<Data, [Path]>().setting(key: fingerprint.toData(), value: [prefix]) : Mapping<Data, [Path]>() }
        return node.missing(prefix: prefix)
    }

    func capture(fingerprintOfContent: Data, content: Data, prefix: Path, previousKey: Data?, keys: Mapping<Data, Data>) -> (Self, Mapping<Data, [Path]>)? {
        guard let digest = Digest(data: fingerprintOfContent) else { return nil }
        if fingerprintOfSymmetricKey != nil, keys[fingerprintOfSymmetricKey!.toData()] == nil { return nil }
        let key = fingerprintOfSymmetricKey != nil ? keys[fingerprintOfSymmetricKey!.toData()] : previousKey
        let symmetricKey = key == nil ? nil : SymmetricKey(data: key!)
        if key != nil, symmetricIV == nil || symmetricKey == nil { return nil }
        let plaintext = key != nil ? SymmetricDelegateType.decrypt(cipherText: content, key: symmetricKey!, iv: symmetricIV!) : content
        guard let finalPlaintext = plaintext else { return nil }
        guard let decodedNode = Artifact(data: finalPlaintext) else { return nil }
        if digest != self.fingerprint { return nil }
        let targetedNode = decodedNode.targeting(targets, prefix: prefix)
        let maskedNode = targetedNode.0.masking(masks, prefix: prefix)
        let shouldMask = maskedNode.0.shouldMask(masks, prefix: prefix)
        let finalNode = (isMasked || shouldMask) ? maskedNode.0.mask(prefix: prefix) : (maskedNode.0, Mapping<Data, [Path]>())
        return (Self(fingerprint: digest, dataItem: finalNode.0, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, complete: finalNode.0.isComplete(), targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: isMasked || shouldMask, isTargeted: isTargeted, symmetricIV: symmetricIV), finalNode.0.missing(prefix: prefix))
    }

    func capture(digestString: Data, content: Data, at route: Path, prefix: Path, previousKey: Data?, keys: Mapping<Data, Data>) -> (Self, Mapping<Data, [Path]>)? {
        if route.isEmpty, dataItem == nil { return capture(fingerprintOfContent: digestString, content: content, prefix: prefix, previousKey: previousKey, keys: keys) }
        guard let node = dataItem else { return nil }
        if fingerprintOfSymmetricKey != nil, keys[fingerprintOfSymmetricKey!.toData()] == nil { return nil }
        let newPreviousKey = fingerprintOfSymmetricKey == nil ? previousKey : keys[fingerprintOfSymmetricKey!.toData()]
        guard let nodeResult = node.capture(digestString: digestString, content: content, at: route, prefix: prefix, previousKey: newPreviousKey, keys: keys) else { return nil }
        return (changing(fingerprint: nil, dataItem: nodeResult.0, complete: nodeResult.0.isComplete()), nodeResult.1)
    }

    func empty() -> Self {
        return Self(fingerprint: fingerprint, fingerprintOfSymmetricKey: fingerprintOfSymmetricKey, symmetricIV: symmetricIV)
    }

    func targeting(_ targets: TrieSet<Edge>, prefix: Path) -> (Self, Mapping<Data, [Path]>) {
        if targets.isEmpty() { return (self, Mapping<Data, [Path]>()) }
        guard let artifact = dataItem else {
            if focused() { return (changing(targets: self.targets.overwrite(with: targets)), Mapping<Data, [Path]>()) }
            return (changing(complete: false, targets: self.targets.overwrite(with: targets)), Mapping<Data, [Path]>().setting(key: fingerprint.toData(), value: [prefix]))
        }
        let childResult = artifact.targeting(targets, prefix: prefix)
        return (changing(dataItem: childResult.0), childResult.1)
    }

    func masking(_ masks: TrieSet<Edge>, prefix: Path) -> (Self, Mapping<Data, [Path]>) {
        if masks.isEmpty() || isMasked { return (self, Mapping<Data, [Path]>()) }
        guard let artifact = dataItem else {
            if focused() { return (changing(masks: masks), Mapping<Data, [Path]>()) }
            return (changing(complete: false, masks: masks), Mapping<Data, [Path]>().setting(key: fingerprint.toData(), value: [prefix]))
        }
        let childResult = artifact.masking(masks, prefix: prefix)
        return (changing(dataItem: childResult.0), childResult.1)
    }

    func mask(prefix: Path) -> (Self, Mapping<Data, [Path]>) {
        if let childResult = dataItem?.mask(prefix: prefix) { return (changing(dataItem: childResult.0, isMasked: true), childResult.1) }
        if focused() { return (changing(isMasked: true), Mapping<Data, [Path]>()) }
        return (changing(complete: false, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: true), Mapping<Data, [Path]>().setting(key: fingerprint.toData(), value: [prefix]))
    }

    func target(prefix: Path) -> (Self, Mapping<Data, [Path]>) {
        return focused() ? (changing(isTargeted: true), Mapping<Data, [Path]>()) : (changing(complete: false, isTargeted: true), Mapping<Data, [Path]>().setting(key: fingerprint.toData(), value: [prefix]))
    }
}
