import Foundation
import CryptoStarterPack

public struct RadixOverlay256: Codable {
    private let rawFullRadix: Radix256!
    private let rawChildren: [Bool : StemOverlay256]!
}

extension RadixOverlay256: RGArtifact {
    public typealias CryptoDelegateType = BaseCrypto
    public typealias Digest = UInt256
}

extension RadixOverlay256: Radix {
    public typealias Symbol = Bool
    public typealias Child = StemOverlay256
    
    public var children: [Bool : StemOverlay256] { return rawChildren }
}

extension RadixOverlay256: RadixOverlay {
    public var fullRadix: Radix256! { return rawFullRadix }
    
    public typealias FullRadix = Radix256
    
    public init(fullRadix: FullRadix, children: [Symbol: Child]) {
        self.rawFullRadix = fullRadix
        self.rawChildren = children
    }
}
