import Foundation
import Bedrock
import AwesomeDictionary

public protocol RadixOverlay: Radix {
    associatedtype FullRadix: Radix
    
    var fullRadix: FullRadix! { get }
    
    init(fullRadix: FullRadix, children: Mapping<Edge, Child>)
    
    func missing() -> Mapping<Digest, [Path]>
    func targeting(_ targets: [[Edge]]) -> (Self, Mapping<Digest, [Path]>)?
    func masking(_ masks: [[Edge]]) -> (Self, Mapping<Digest, [Path]>)?
    func mask() -> (Self, Mapping<Digest, [Path]>)?
}

public extension RadixOverlay where Child: StemOverlay, FullRadix.Digest == Digest {
    var prefix: [Edge] { return fullRadix.prefix }
    var value: [Edge] { return fullRadix.value }
    
    init(prefix: [Edge], value: [Edge], children: Mapping<Edge, Child>) {
        let newChildren = children.elements().reduce(Mapping<Edge, FullRadix.Child>()) { (result, entry) -> Mapping<Edge, FullRadix.Child> in
            return result.setting(key: entry.0, value: FullRadix.Child(digest: entry.1.digest))
        }
        self.init(fullRadix: FullRadix(prefix: prefix, value: value, children: newChildren), children: children)
    }
    
    init(fullRadix: FullRadix) {
        let newChildren = fullRadix.children.elements().reduce(Mapping<Edge, Child>()) { (result, entry) -> Mapping<Edge, Child> in
            return result.setting(key: entry.0, value: Child(digest: entry.1.digest))
        }
        self.init(fullRadix: fullRadix, children: newChildren)
    }
    
    func toBoolArray() -> [Bool] {
        return fullRadix.toBoolArray()
    }
    
    init?(raw: [Bool]) {
        guard let fullNode = FullRadix(raw: raw) else { return nil }
        self.init(fullRadix: fullNode)
    }
    
    func missing() -> Mapping<Digest, [Path]> {
        if children.isEmpty() { return Mapping<Digest, [Path]>() }
        return children.elements().filter { $0.1.targets != nil || $0.1.masks != nil || $0.1.isMasked }.map { $0.1.missing().prepend($0.0.toString()) }.reduce(Mapping<Digest, [Path]>(), +)
    }
    
    func targeting(_ targets: [[Edge]]) -> (Self, Mapping<Digest, [Path]>)? {
        return children.elements().reduce((self, Mapping<Digest, [Path]>()), { (result, entry) -> (Self, Mapping<Digest, [Path]>)? in
            let childSubs = targets.filter { $0.starts(with: [entry.0]) }
            guard let result = result else { return nil }
            if childSubs.isEmpty { return result }
            guard let modifiedChild = entry.1.targeting(childSubs) else { return nil }
            return (Self(fullRadix: fullRadix, children: result.0.children.setting(key: entry.0, value: modifiedChild.0)), result.1 + modifiedChild.1.prepend(entry.0.toString()))
        })
    }
    
    func masking(_ masks: [[Edge]]) -> (Self, Mapping<Digest, [Path]>)? {
        return children.elements().reduce((self, Mapping<Digest, [Path]>()), { (result, entry) -> (Self, Mapping<Digest, [Path]>)? in
            let childSubAlls = masks.filter { $0.starts(with: [entry.0]) }
            guard let result = result else { return nil }
            if childSubAlls.isEmpty { return result }
            guard let modifiedChild = entry.1.masking(childSubAlls) else { return nil }
            return (Self(fullRadix: fullRadix, children: result.0.children.setting(key: entry.0, value: modifiedChild.0)), result.1 + modifiedChild.1.prepend(entry.0.toString()))
        })
    }
    
    func mask() -> (Self, Mapping<Digest, [Path]>)? {
        return children.elements().reduce((self, Mapping<Digest, [Path]>()), { (result, entry) -> (Self, Mapping<Digest, [Path]>)? in
            guard let result = result else { return nil }
            guard let modifiedChild = entry.1.mask() else { return nil }
            return (Self(fullRadix: fullRadix, children: result.0.children.setting(key: entry.0, value: modifiedChild.0)), result.1 + (modifiedChild.1.prepend(entry.0.toString())))
        })
    }
}
