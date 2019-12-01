import Foundation
import Bedrock
import CryptoStarterPack
import AwesomeDictionary

public struct Radix256: Codable {
    private let rawPrefix: [Edge]!
    private let rawValue: [Edge]!
    private let rawChildren: [Mapping<Edge, Child>]!
}

extension Radix256: RGRadix {
    public typealias Child = RadixAddress256
    public typealias Edge = String
    public typealias Digest = UInt256

    public var prefix: [Edge] { return rawPrefix }
    public var value: [Edge] { return rawValue }
    public var children: Mapping<Edge, Child> { return rawChildren.first! }

    public init(prefix: [Edge], value: [Edge], children: Mapping<Edge, Child>) {
        self.rawPrefix = prefix
        self.rawValue = value
        self.rawChildren = [children]
    }
}
