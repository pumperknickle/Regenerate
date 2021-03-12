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

    var digest: Digest! { get }
    var artifact: Artifact? { get }
    var symmetricKeyHash: Digest? { get }
    var symmetricIV: SymmetricIV? { get }

    var complete: Bool! { get }
    var targets: TrieSet<Edge>! { get }
    var masks: TrieSet<Edge>! { get }
    var isMasked: Bool! { get }
    var isTargeted: Bool! { get }

    init(digest: Digest, symmetricKeyHash: Digest?, symmetricIV: SymmetricIV?)
    init(digest: Digest, artifact: Artifact?, symmetricKeyHash: Digest?, symmetricIV: SymmetricIV?, complete: Bool)
    init(digest: Digest, artifact: Artifact?, symmetricKeyHash: Digest?, complete: Bool, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool, isTargeted: Bool, symmetricIV: SymmetricIV?)

    func changing(digest: Digest?, artifact: Artifact?, complete: Bool?, targets: TrieSet<Edge>?, masks: TrieSet<Edge>?, isMasked: Bool?, isTargeted: Bool?) -> Self
    func computedCompleteness() -> Bool
}

public extension Addressable {
    func encrypt(allKeys: CoveredTrie<String, Data>, commonIv: Data, keyRoot: Bool) -> Self? {
        guard let artifact = artifact else { return nil }
        guard let encryptedArtifact = artifact.encrypt(allKeys: allKeys, commonIv: commonIv) else { return nil }
        guard let symmetricKeyData = allKeys.cover else { return changing(artifact: encryptedArtifact) }
        guard let symmetricKey = SymmetricKey(data: Data(symmetricKeyData)) else { return nil }
        guard let dataIV = CryptoDelegateType.hash(commonIv) else { return nil }
        guard let IV = SymmetricIV(data: dataIV) else { return nil }
        guard let ciphertext = SymmetricDelegateType.encrypt(plaintext: encryptedArtifact.pruning(), key: symmetricKey, iv: IV) else { return nil }
        guard let ciphertextHashOutput = CryptoDelegateType.hash(ciphertext) else { return nil }
        guard let ciphertextDigest = Digest(data: ciphertextHashOutput) else { return nil }
        if !keyRoot { return Self(digest: ciphertextDigest, artifact: encryptedArtifact, symmetricKeyHash: nil, complete: complete, targets: targets, masks: masks, isMasked: isMasked, isTargeted: isTargeted, symmetricIV: IV) }
        guard let symmetricKeyHashData = BaseCrypto.hash(symmetricKeyData) else { return nil }
        guard let symmetricKeyHash = Digest(data: symmetricKeyHashData) else { return nil }
        return Self(digest: ciphertextDigest, artifact: encryptedArtifact, symmetricKeyHash: symmetricKeyHash, complete: complete, targets: targets, masks: masks, isMasked: isMasked, isTargeted: isTargeted, symmetricIV: IV)
    }

    func isComplete() -> Bool {
        return complete
    }

    func focused() -> Bool { return !(targets.isEmpty() && masks.isEmpty() && !isMasked && !isTargeted) }

    func changing(digest: Digest? = nil, artifact: Artifact? = nil, complete: Bool? = nil, targets: TrieSet<Edge>? = nil, masks: TrieSet<Edge>? = nil, isMasked: Bool? = nil, isTargeted: Bool? = nil) -> Self {
        return Self(digest: digest ?? self.digest, artifact: artifact ?? self.artifact, symmetricKeyHash: symmetricKeyHash, complete: complete ?? self.complete, targets: targets ?? self.targets, masks: masks ?? self.masks, isMasked: isMasked ?? self.isMasked, isTargeted: isTargeted ?? self.isTargeted, symmetricIV: symmetricIV)
    }

    init?(artifact: Artifact, symmetricKeyHash: Digest? = nil, symmetricIV: SymmetricIV? = nil, complete: Bool) {
        let nodeData = artifact.pruning().toData()
        guard let artifactHashOutput = CryptoDelegateType.hash(nodeData) else { return nil }
        guard let digest = Digest(data: artifactHashOutput) else { return nil }
        self.init(digest: digest, artifact: artifact, symmetricKeyHash: symmetricKeyHash, symmetricIV: symmetricIV, complete: complete)
    }

    init(digest: Digest, symmetricKeyHash: Digest? = nil, symmetricIV: SymmetricIV? = nil) {
        self.init(digest: digest, artifact: nil, symmetricKeyHash: symmetricKeyHash, symmetricIV: symmetricIV, complete: true)
    }

    init(digest: Digest, artifact: Artifact, symmetricKeyHash: Digest?, symmetricIV: SymmetricIV?) {
        self.init(digest: digest, artifact: artifact, symmetricKeyHash: symmetricKeyHash, symmetricIV: symmetricIV, complete: artifact.isComplete())
    }

    init(digest: Digest, artifact: Artifact?, symmetricKeyHash: Digest?, symmetricIV: SymmetricIV?, complete: Bool) {
        self.init(digest: digest, artifact: artifact, symmetricKeyHash: symmetricKeyHash, complete: complete, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: false, isTargeted: false, symmetricIV: symmetricIV)
    }

    init?(artifact: Artifact, symmetricKeyHash: Digest?, symmetricIV: SymmetricIV?) {
        self.init(artifact: artifact, symmetricKeyHash: symmetricKeyHash, symmetricIV: symmetricIV, complete: artifact.isComplete())
    }

    func toData() -> Data {
        return try! JSONEncoder().encode(empty())
    }

    init?(data: Data) {
        guard let decoded = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = decoded
    }

    func computedCompleteness() -> Bool {
        guard let node = artifact else { return !focused() }
        return node.isComplete()
    }

    func contents(previousKey: Data? = nil, keys: Mapping<Data, Data> = Mapping<Data, Data>()) -> Mapping<Data, Data> {
        guard let node = artifact else { return Mapping<Data, Data>() }
        guard let symmetricKeyHash = symmetricKeyHash else {
            guard let previousKey = previousKey else { return node.contents(previousKey: nil, keys: keys).setting(key: digest.toData(), value: node.pruning().toData()) }
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
        guard let node = artifact else { return focused() ? Mapping<Data, [Path]>().setting(key: digest.toData(), value: [prefix]) : Mapping<Data, [Path]>() }
        return node.missing(prefix: prefix)
    }

    func capture(digestString: Data, content: Data, prefix: Path, previousKey: Data?, keys: Mapping<Data, Data>) -> (Self, Mapping<Data, [Path]>)? {
        guard let digest = Digest(data: digestString) else { return nil }
        if symmetricKeyHash != nil, keys[symmetricKeyHash!.toData()] == nil { return nil }
        let key = symmetricKeyHash != nil ? keys[symmetricKeyHash!.toData()] : previousKey
        let symmetricKey = key == nil ? nil : SymmetricKey(data: key!)
        if key != nil, symmetricIV == nil || symmetricKey == nil { return nil }
        let plaintext = key != nil ? SymmetricDelegateType.decrypt(cipherText: content, key: symmetricKey!, iv: symmetricIV!) : content
        guard let finalPlaintext = plaintext else { return nil }
        guard let decodedNode = Artifact(data: finalPlaintext) else { return nil }
        if digest != self.digest { return nil }
        let targetedNode = decodedNode.targeting(targets, prefix: prefix)
        let maskedNode = targetedNode.0.masking(masks, prefix: prefix)
        let shouldMask = maskedNode.0.shouldMask(masks, prefix: prefix)
        let finalNode = (isMasked || shouldMask) ? maskedNode.0.mask(prefix: prefix) : (maskedNode.0, Mapping<Data, [Path]>())
        return (Self(digest: digest, artifact: finalNode.0, symmetricKeyHash: symmetricKeyHash, complete: finalNode.0.isComplete(), targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: isMasked || shouldMask, isTargeted: isTargeted, symmetricIV: symmetricIV), finalNode.0.missing(prefix: prefix))
    }

    func capture(digestString: Data, content: Data, at route: Path, prefix: Path, previousKey: Data?, keys: Mapping<Data, Data>) -> (Self, Mapping<Data, [Path]>)? {
        if route.isEmpty, artifact == nil { return capture(digestString: digestString, content: content, prefix: prefix, previousKey: previousKey, keys: keys) }
        guard let node = artifact else { return nil }
        if symmetricKeyHash != nil, keys[symmetricKeyHash!.toData()] == nil { return nil }
        let newPreviousKey = symmetricKeyHash == nil ? previousKey : keys[symmetricKeyHash!.toData()]
        guard let nodeResult = node.capture(digestString: digestString, content: content, at: route, prefix: prefix, previousKey: newPreviousKey, keys: keys) else { return nil }
        return (changing(digest: nil, artifact: nodeResult.0, complete: nodeResult.0.isComplete()), nodeResult.1)
    }

    func empty() -> Self {
        return Self(digest: digest, symmetricKeyHash: symmetricKeyHash, symmetricIV: symmetricIV)
    }

    func targeting(_ targets: TrieSet<Edge>, prefix: Path) -> (Self, Mapping<Data, [Path]>) {
        if targets.isEmpty() { return (self, Mapping<Data, [Path]>()) }
        guard let artifact = artifact else {
            if focused() { return (changing(targets: self.targets.overwrite(with: targets)), Mapping<Data, [Path]>()) }
            return (changing(complete: false, targets: self.targets.overwrite(with: targets)), Mapping<Data, [Path]>().setting(key: digest.toData(), value: [prefix]))
        }
        let childResult = artifact.targeting(targets, prefix: prefix)
        return (changing(artifact: childResult.0), childResult.1)
    }

    func masking(_ masks: TrieSet<Edge>, prefix: Path) -> (Self, Mapping<Data, [Path]>) {
        if masks.isEmpty() || isMasked { return (self, Mapping<Data, [Path]>()) }
        guard let artifact = artifact else {
            if focused() { return (changing(masks: masks), Mapping<Data, [Path]>()) }
            return (changing(complete: false, masks: masks), Mapping<Data, [Path]>().setting(key: digest.toData(), value: [prefix]))
        }
        let childResult = artifact.masking(masks, prefix: prefix)
        return (changing(artifact: childResult.0), childResult.1)
    }

    func mask(prefix: Path) -> (Self, Mapping<Data, [Path]>) {
        if let childResult = artifact?.mask(prefix: prefix) { return (changing(artifact: childResult.0, isMasked: true), childResult.1) }
        if focused() { return (changing(isMasked: true), Mapping<Data, [Path]>()) }
        return (changing(complete: false, targets: TrieSet<Edge>(), masks: TrieSet<Edge>(), isMasked: true), Mapping<Data, [Path]>().setting(key: digest.toData(), value: [prefix]))
    }

    func target(prefix: Path) -> (Self, Mapping<Data, [Path]>) {
        return focused() ? (changing(isTargeted: true), Mapping<Data, [Path]>()) : (changing(complete: false, isTargeted: true), Mapping<Data, [Path]>().setting(key: digest.toData(), value: [prefix]))
    }
}
