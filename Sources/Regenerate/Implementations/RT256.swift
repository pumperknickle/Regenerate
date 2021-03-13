import AwesomeDictionary
import Bedrock
import Foundation

public struct RT256<Key: DataEncodable, Value: DataEncodable>: Codable {
    private let rawRoot: Root!
    private let rawPaths: Mapping<Digest, [Path]>!
}

extension RT256: Regenerative {
    public typealias Root = RadixAddress256

    public var root: Root { return rawRoot }
    public var keyPaths: Mapping<Digest, [Path]> { return rawPaths }

    public init(root: Root, paths: Mapping<Digest, [Path]>) {
        rawRoot = root
        rawPaths = paths
    }
}

extension RT256: RGRT {
    public func decodeKey(symbols: [String]) -> Data? { return Data(hexString: symbols.reduce("", +)) }
    public func encodeKey(key: Data) -> [String]? { return key.toHexString().map { "\($0)" } }
    public func decodeValue(symbols: [String]) -> Data? { return Data(hexString: symbols.reduce("", +)) }
    public func encodeValue(value: Data) -> [String]? { return value.toHexString().map { "\($0)" } }
}
