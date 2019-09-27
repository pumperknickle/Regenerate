import Foundation
import Bedrock
import CryptoStarterPack
import TMap

public struct RadixOverlay256: Codable {
    private let rawFullRadix: FullRadix!
    private let rawChildren: TMap<Edge, Child>!
}

extension RadixOverlay256: RGArtifact {
    public typealias CryptoDelegateType = BaseCrypto
    public typealias Digest = UInt256
}

extension RadixOverlay256: Radix {
    public typealias Edge = String
    public typealias Child = StemOverlay256
    
    public var children: TMap<Edge, Child> { return rawChildren }
}

extension RadixOverlay256: RadixOverlay {
    public var fullRadix: FullRadix! { return rawFullRadix }
    
    public typealias FullRadix = Radix256
    
    public init(fullRadix: FullRadix, children: TMap<Edge, Child>) {
        self.rawFullRadix = fullRadix
        self.rawChildren = children
    }
}
