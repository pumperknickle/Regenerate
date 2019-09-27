import Foundation
import Bedrock

public protocol RTOverlay: RGRT where Root: StemOverlay {
    func targeting(_ targets: [Key]) -> Self?
    func masking(_ masks: [Key]) -> Self?
}

public extension RTOverlay {
    func targeting(_ targets: [Key]) -> Self? {
        let symbolEncodedKeys = targets.map { encodeKey($0.toBoolArray()) }
        if symbolEncodedKeys.contains(nil) { return nil }
        guard let result = root.targeting(symbolEncodedKeys.map { $0! }) else { return nil }
        return Self(root: result.0, paths: keyPaths + result.1)
    }
    
    func masking(_ masks: [Key]) -> Self? {
        let symbolEncodedKeys = masks.map { encodeKey($0.toBoolArray()) }
        if symbolEncodedKeys.contains(nil) { return nil }
        guard let result = root.masking(symbolEncodedKeys.map { $0! }) else { return nil }
        return Self(root: result.0, paths: keyPaths + result.1)
    }
}
