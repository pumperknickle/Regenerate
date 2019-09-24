import Foundation
import CryptoStarterPack

public struct RadixOverlay256: Codable {
    private let rawFullRadix: FullRadix!
    private let rawChildren: [Symbol : Child]!
}

extension RadixOverlay256: RGArtifact {
    public typealias CryptoDelegateType = BaseCrypto
    public typealias Digest = UInt256
}

extension RadixOverlay256: Radix {
    public typealias Symbol = String
    public typealias Child = StemOverlay256
    
    public var children: [Symbol : Child] { return rawChildren }
}

extension RadixOverlay256: RadixOverlay {
    public var fullRadix: FullRadix! { return rawFullRadix }
    
    public typealias FullRadix = Radix256
    
    public init(fullRadix: FullRadix, children: [Symbol: Child]) {
        self.rawFullRadix = fullRadix
        self.rawChildren = children
    }
}
