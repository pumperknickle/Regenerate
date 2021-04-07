import AwesomeDictionary
import Bedrock
import CryptoStarterPack
import Foundation

public struct Radix256 {
    private let rawPrefix: [Edge]!
    private let rawValue: [Edge]!
    private let rawChildren: Mapping<Edge, Child>!
}

extension Radix256: RGRadix {
    public typealias Child = RadixAddress256
    public typealias Edge = String
    public typealias Digest = UInt256

    public var prefix: [Edge] { return rawPrefix }
    public var value: [Edge] { return rawValue }
    public var children: Mapping<Edge, Child> { return rawChildren }

    public init(prefix: [Edge], value: [Edge], children: Mapping<Edge, Child>) {
        rawPrefix = prefix
        rawValue = value
        rawChildren = children
    }
}

extension Radix256: Codable {
    private enum CodingKeys: String, CodingKey {
        case prefix
        case value
        case children
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let rawPrefix = try values.decode([Edge].self, forKey: .prefix)
        let rawValue = try values.decode([Edge].self, forKey: .value)
        let rawChildren = try values.decode(Mapping<Edge, Child>.self, forKey: .children)
        self.init(prefix: rawPrefix, value: rawValue, children: rawChildren)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawPrefix, forKey: .prefix)
        try container.encode(rawValue, forKey: .value)
        try container.encode(rawChildren, forKey: .children)
        return
    }
}
