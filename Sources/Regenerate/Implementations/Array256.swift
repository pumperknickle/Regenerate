import AwesomeDictionary
import AwesomeTrie
import Bedrock
import Foundation

public struct Array256<Element: Addressable> where Element.Digest == UInt256 {
    private let rawCore: CoreType!
    private let rawIncompleteChildren: Set<String>?
    private let rawChildren: Mapping<String, Value>?
    private let rawTargets: TrieSet<Edge>?
    private let rawMasks: TrieSet<Edge>?
    private let rawIsMasked: Singleton?
    private let rawLength: UInt256!

    public init(core: CoreType, incompleteChildren: Set<String>, children: Mapping<String, Value>, targets: TrieSet<Edge>, masks: TrieSet<Edge>, isMasked: Bool, length: UInt256) {
        rawCore = core
        rawIncompleteChildren = incompleteChildren.isEmpty ? nil : incompleteChildren
        rawChildren = children.isEmpty() ? nil : children
        rawTargets = targets.isEmpty() ? nil : targets
        rawMasks = masks.isEmpty() ? nil : masks
        rawIsMasked = isMasked ? .void : nil
        rawLength = length
    }
}

extension Array256: RGArray {
    public typealias Key = UInt256
    public typealias Value = Element
    public typealias CoreType = RT256<Key, Value>

    public var core: CoreType! { return rawCore }
    public var incompleteChildren: Set<String>! { return rawIncompleteChildren ?? Set<String>([]) }
    public var children: Mapping<String, Value>! { return rawChildren ?? Mapping<String, Value>() }
    public var targets: TrieSet<Edge>! { return rawTargets ?? TrieSet<Edge>() }
    public var masks: TrieSet<Edge>! { return rawMasks ?? TrieSet<Edge>() }
    public var isMasked: Bool! { return rawIsMasked != nil ? true : false }
    public var length: UInt256! { return rawLength }
}

extension Array256: Codable {
    private enum CodingKeys: String, CodingKey {
        case core
        case incompleteChildren
        case children
        case targets
        case masks
        case isMasked
        case length
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawCore = try values.decode(CoreType.self, forKey: .core)
        let rawIncompleteChildren = try? values.decode(Set<String>.self, forKey: .incompleteChildren)
        let rawChildren = try? values.decode(Mapping<String, Value>.self, forKey: .children)
        let rawTargets = try? values.decode(TrieSet<Edge>.self, forKey: .targets)
        let rawMasks = try? values.decode(TrieSet<Edge>.self, forKey: .masks)
        let rawIsMasked = try? values.decode(Singleton.self, forKey: .isMasked)
        let rawLength = try values.decode(UInt256.self, forKey: .length)
        self.init(core: rawCore, incompleteChildren: rawIncompleteChildren ?? Set<String>([]), children: rawChildren ?? Mapping<String, Value>(), targets: rawTargets ?? TrieSet<Edge>(), masks: rawMasks ?? TrieSet<Edge>(), isMasked: rawIsMasked != nil ? true : false, length: rawLength)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawCore, forKey: .core)
        try container.encodeIfPresent(rawIncompleteChildren, forKey: .incompleteChildren)
        try container.encodeIfPresent(rawChildren, forKey: .children)
        try container.encodeIfPresent(rawTargets, forKey: .targets)
        try container.encodeIfPresent(rawMasks, forKey: .masks)
        try container.encodeIfPresent(rawIsMasked, forKey: .isMasked)
        try container.encode(rawLength, forKey: .length)
        return
    }
}
