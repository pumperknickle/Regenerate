import Foundation
import CryptoStarterPack

public protocol RadixOverlay: Radix {
    associatedtype FullRadix: Radix
    
    var fullRadix: FullRadix! { get }
    
    init(fullRadix: FullRadix, children: [Symbol: Child])
    
    func missing() -> [Digest: [Path]]
    func targeting(_ targets: [[Symbol]]) -> (Self, [Digest: [Path]])?
    func masking(_ masks: [[Symbol]]) -> (Self, [Digest: [Path]])?
    func mask() -> (Self, [Digest: [Path]])?
}

public extension RadixOverlay where Child: StemOverlay, FullRadix.Symbol == Symbol, FullRadix.Digest == Digest {
    var prefix: [Symbol] { return fullRadix.prefix }
    var value: [Symbol] { return fullRadix.value }
    
    init(prefix: [Symbol], value: [Symbol], children: [Symbol : Child]) {
        self.init(fullRadix: FullRadix(prefix: prefix, value: value, children: children.mapValues { FullRadix.Child(digest: $0.digest) }), children: children)
    }
    
    init(fullRadix: FullRadix) {
        self.init(fullRadix: fullRadix, children: fullRadix.children.mapValues { Child(digest: $0.digest) })
    }
    
    func serialize() -> Data? {
        return fullRadix.serialize()
    }
    
    init?(content: Data) {
        guard let fullNode = FullRadix(content: content) else { return nil }
        self.init(fullRadix: fullNode)
    }
    
    func missing() -> [Digest: [Path]] {
        if children.isEmpty { return [:] }
        return children.filter { $0.value.targets != nil || $0.value.masks != nil || $0.value.isMasked }.map { $0.value.missing().prepend($0.key.toString()) }.reduce([:] as [Digest: [Path]], +)
    }
    
    func targeting(_ targets: [[Symbol]]) -> (Self, [Digest: [Path]])? {
        return children.reduce((self, [:]), { (result, entry) -> (Self, [Digest: [Path]])? in
            let childSubs = targets.filter { $0.starts(with: [entry.key]) }
            guard let result = result else { return nil }
            if childSubs.isEmpty { return result }
            guard let modifiedChild = entry.value.targeting(childSubs) else { return nil }
            let newChildren = result.0.children.setting(entry.key, withValue: modifiedChild.0)
            let extendedRoutes = result.1 + modifiedChild.1.prepend(entry.key.toString())
            return (Self(fullRadix: fullRadix, children: newChildren), extendedRoutes)
        })
    }
    
    func masking(_ masks: [[Symbol]]) -> (Self, [Digest: [Path]])? {
        return children.reduce((self, [:]), { (result, entry) -> (Self, [Digest: [Path]])? in
            let childSubAlls = masks.filter { $0.starts(with: [entry.key]) }
            guard let result = result else { return nil }
            if childSubAlls.isEmpty { return result }
            guard let modifiedChild = entry.value.masking(childSubAlls) else { return nil }
            let newChildren = result.0.children.setting(entry.key, withValue: modifiedChild.0)
            let extendedRoutes = result.1 + modifiedChild.1.prepend(entry.key.toString())
            return (Self(fullRadix: fullRadix, children: newChildren), extendedRoutes)
        })
    }
    
    func mask() -> (Self, [Digest: [Path]])? {
        return children.reduce((self, [:]), { (result, entry) -> (Self, [Digest: [Path]])? in
            guard let result = result else { return nil }
            guard let modifiedChild = entry.value.mask() else { return nil }
            let newChildren = result.0.children.setting(entry.key, withValue: modifiedChild.0)
            let extendedRoutes = result.1 + (modifiedChild.1.prepend(entry.key.toString()))
            return (Self(fullRadix: fullRadix, children: newChildren), extendedRoutes)
        })
    }
}
