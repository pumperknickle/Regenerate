import Foundation
import CryptoStarterPack

public protocol RadixOverlay: Radix {
    associatedtype FullRadix: Radix
    
    var fullRadix: FullRadix! { get }
    
    init(fullRadix: FullRadix, children: [Edge: Child])
    
    func missing() -> [Digest: [Path]]
    func targeting(_ targets: [[Edge]]) -> (Self, [Digest: [Path]])?
    func masking(_ masks: [[Edge]]) -> (Self, [Digest: [Path]])?
    func mask() -> (Self, [Digest: [Path]])?
}

public extension RadixOverlay where Child: StemOverlay, FullRadix.Edge == Edge, FullRadix.Digest == Digest {
    var prefix: [Edge] { return fullRadix.prefix }
    var value: [Edge] { return fullRadix.value }
    
    init(prefix: [Edge], value: [Edge], children: [Edge : Child]) {
        self.init(fullRadix: FullRadix(prefix: prefix, value: value, children: children.mapValues { FullRadix.Child(digest: $0.digest) }), children: children)
    }
    
    init(fullRadix: FullRadix) {
        self.init(fullRadix: fullRadix, children: fullRadix.children.mapValues { Child(digest: $0.digest) })
    }
    
    func toBoolArray() -> [Bool] {
        return fullRadix.toBoolArray()
    }
    
    init?(raw: [Bool]) {
        guard let fullNode = FullRadix(raw: raw) else { return nil }
        self.init(fullRadix: fullNode)
    }
    
    func missing() -> [Digest: [Path]] {
        if children.isEmpty { return [:] }
        return children.filter { $0.value.targets != nil || $0.value.masks != nil || $0.value.isMasked }.map { $0.value.missing().prepend($0.key.toString()) }.reduce([:] as [Digest: [Path]], +)
    }
    
    func targeting(_ targets: [[Edge]]) -> (Self, [Digest: [Path]])? {
        return children.reduce((self, [:]), { (result, entry) -> (Self, [Digest: [Path]])? in
            let childSubs = targets.filter { $0.starts(with: [entry.key]) }
            guard let result = result else { return nil }
            if childSubs.isEmpty { return result }
            guard let modifiedChild = entry.value.targeting(childSubs) else { return nil }
            return (Self(fullRadix: fullRadix, children: result.0.children.setting(entry.key, withValue: modifiedChild.0)), result.1 + modifiedChild.1.prepend(entry.key.toString()))
        })
    }
    
    func masking(_ masks: [[Edge]]) -> (Self, [Digest: [Path]])? {
        return children.reduce((self, [:]), { (result, entry) -> (Self, [Digest: [Path]])? in
            let childSubAlls = masks.filter { $0.starts(with: [entry.key]) }
            guard let result = result else { return nil }
            if childSubAlls.isEmpty { return result }
            guard let modifiedChild = entry.value.masking(childSubAlls) else { return nil }
            return (Self(fullRadix: fullRadix, children: result.0.children.setting(entry.key, withValue: modifiedChild.0)), result.1 + modifiedChild.1.prepend(entry.key.toString()))
        })
    }
    
    func mask() -> (Self, [Digest: [Path]])? {
        return children.reduce((self, [:]), { (result, entry) -> (Self, [Digest: [Path]])? in
            guard let result = result else { return nil }
            guard let modifiedChild = entry.value.mask() else { return nil }
            return (Self(fullRadix: fullRadix, children: result.0.children.setting(entry.key, withValue: modifiedChild.0)), result.1 + (modifiedChild.1.prepend(entry.key.toString())))
        })
    }
}
