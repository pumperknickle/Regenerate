import AwesomeDictionary
import Bedrock
import CryptoStarterPack
import Foundation

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
        rawPrefix = prefix
        rawValue = value
        rawChildren = [children]
    }
}
