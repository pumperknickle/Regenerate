import Foundation
import CryptoStarterPack

public protocol StemOverlay: Stem {    
    var targets: [[Edge]]? { get }
    var masks: [[Edge]]? { get }
    var isMasked: Bool! { get }
    
    func targeting(_ targets: [[Edge]]) -> (Self, [Digest: [Path]])?
    func masking(_ masks: [[Edge]]) -> (Self, [Digest: [Path]])?
    func mask() -> (Self, [Digest: [Path]])?
    
    init(digest: Digest, artifact: Artifact?, complete: Bool, targets: [[Edge]]?, masks: [[Edge]]?, isMasked: Bool)
}

public extension StemOverlay where Artifact: RadixOverlay, Artifact.Child == Self {
    init(digest: Digest) {
        self.init(digest: digest, artifact: nil, complete: false)
    }
    
    init(digest: Digest, artifact: Artifact?, targets: [[Edge]]?, masks: [[Edge]]?, isMasked: Bool) {
        guard let finalArtifact = artifact else {
            self.init(digest: digest, artifact: nil, complete: false, targets: targets, masks: masks, isMasked: isMasked)
            return
        }
        self.init(digest: digest, artifact: finalArtifact, complete: finalArtifact.isComplete(), targets: targets, masks: masks, isMasked: isMasked)
    }
    
    func changing(digest: Digest? = nil, artifact: Artifact? = nil, complete: Bool? = nil) -> Self {
        return Self(digest: digest == nil ? self.digest : digest!, artifact: artifact == nil ? self.artifact : artifact!, complete: complete == nil ? self.complete : complete!, targets: self.targets, masks: self.masks, isMasked: self.isMasked)
    }
    
    func changing(subscribed: [[Edge]]? = nil, subscribeAll: [[Edge]]? = nil, allSubscribed: Bool) -> Self {
        if complete && self.targets == nil && self.masks == nil && !self.isMasked && (subscribed != nil || subscribeAll != nil || allSubscribed) {
            return Self(digest: digest, artifact: artifact, complete: false, targets: subscribed == nil ? self.targets : subscribed!, masks: subscribeAll == nil ? self.masks : subscribeAll!, isMasked: allSubscribed)
        }
        return Self(digest: digest, artifact: artifact, complete: complete, targets: subscribed == nil ? self.targets : subscribed!, masks: subscribeAll == nil ? self.masks : subscribeAll!, isMasked: allSubscribed)
    }
    
    func missing() -> [Digest : [Path]] {
        if targets == nil && masks == nil && !isMasked { return [:] }
        guard let node = artifact else { return [digest: [[]]] }
        return node.missing()
    }
    
    func capture(digest: Digest, content: [Bool]) -> (Self, [Digest : [Path]])? {
        guard let decodedNode = Artifact(raw: content) else { return nil }
        let childSubs = targets?.filter { $0.starts(with: decodedNode.prefix) && $0.count > decodedNode.prefix.count }.map { Array($0.dropFirst(decodedNode.prefix.count)) }
        let childSubAlls = masks?.filter { $0.starts(with: decodedNode.prefix) && $0.count > decodedNode.prefix.count }.map { Array($0.dropFirst(decodedNode.prefix.count)) }
        guard let childResultWithSubs = (childSubs == nil || childSubs!.isEmpty) ? (decodedNode, [:]) : decodedNode.targeting(childSubs!) else { return nil }
        guard let childResultWithSubAlls = (childSubAlls == nil || childSubAlls!.isEmpty) ? (childResultWithSubs.0, [:]) : childResultWithSubs.0.masking(childSubAlls!) else { return nil }
        let localSubs = targets?.filter { !$0.starts(with: decodedNode.prefix) || $0.count <= decodedNode.prefix.count }
        let localSubAlls = masks?.filter { !$0.starts(with: decodedNode.prefix) || $0.count <= decodedNode.prefix.count }
        let allSubResult = localSubAlls != nil && localSubAlls!.contains(where: { childResultWithSubAlls.0.prefix.starts(with: $0) })
        let finalAllSubResult = allSubResult || isMasked
        guard let finalChildResult = finalAllSubResult ? childResultWithSubAlls.0.mask() : (childResultWithSubAlls.0, [:]) else { return nil }
        return (Self(digest: digest, artifact: finalChildResult.0, targets: localSubs, masks: localSubAlls, isMasked: finalAllSubResult), childResultWithSubAlls.1 + childResultWithSubs.1 + finalChildResult.1)
    }
    
    func capture(digest: Digest, content: [Bool], at route: Path) -> (Self, [Digest : [Path]])? {
        if targets == nil && masks == nil && !isMasked { return nil }
        if route.isEmpty && artifact == nil { return capture(digest: digest, content: content) }
        guard let node = artifact else { return nil }
        guard let modifiedNode = node.capture(digest: digest, content: content, at: route) else { return nil }
        return (Self(digest: self.digest, artifact: modifiedNode.0, targets: targets, masks: masks, isMasked: isMasked), modifiedNode.1)
    }
    
    func targeting(_ subs: [[Edge]]) -> (Self, [Digest: [Path]])? {
        guard let node = artifact else {
            if targets == nil && masks == nil && !isMasked { return (changing(subscribed: (targets ?? []) + subs, allSubscribed: isMasked), [digest: [[]]]) }
            return (changing(subscribed: (targets ?? []) + subs, allSubscribed: isMasked), [:])
        }
        let childSubs = subs.filter { $0.starts(with: node.prefix) && $0.count > node.prefix.count }
        let localSubs = subs.filter { !$0.starts(with: node.prefix) || $0.count <= node.prefix.count }
        guard let childResult = node.targeting(childSubs) else { return nil }
        return (Self(digest: digest, artifact: childResult.0, complete: childResult.0.isComplete(), targets: localSubs + (targets ?? []), masks: masks, isMasked: isMasked), childResult.1)
    }
    
    func masking(_ subAlls: [[Edge]]) -> (Self, [Digest: [Path]])? {
        guard let node = artifact else {
            if targets == nil && masks == nil && !isMasked {
                return (changing(subscribeAll: (masks ?? []) + subAlls, allSubscribed: isMasked), [digest: [[]]])
            }
            return (changing(subscribeAll: (masks ?? []) + subAlls, allSubscribed: isMasked), [:])
        }
        let childSubs = subAlls.filter { $0.starts(with: node.prefix) && $0.count > node.prefix.count }
        let localSubs = subAlls.filter { !$0.starts(with: node.prefix) || $0.count <= node.prefix.count }
        let allSubResult = localSubs.contains(where: { node.prefix.starts(with: $0) })
        guard let childResult = node.masking(childSubs) else { return nil }
        return (Self(digest: digest, artifact: childResult.0, complete: childResult.0.isComplete(), targets: targets, masks: localSubs + (masks ?? []), isMasked: isMasked || allSubResult), childResult.1)
    }
    
    func mask() -> (Self, [Digest: [Path]])? {
        guard let node = artifact else {
            if targets == nil && masks == nil && !isMasked {
                return (changing(allSubscribed: true), [digest: [[]]])
            }
            return (changing(allSubscribed: true), [:])
        }
        guard let childResult = node.mask() else { return nil }
        return (Self(digest: digest, artifact: childResult.0, targets: targets, masks: masks, isMasked: true), childResult.1)
    }
}
