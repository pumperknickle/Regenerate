import Foundation
import Bedrock
import AwesomeDictionary

public struct RT256<Key: BinaryEncodable, Value: BinaryEncodable>: Codable {
    private let rawRoot: Root!
    private let rawPaths: Mapping<String, [Path]>!
}

extension RT256: Regenerative {
    public typealias Root = RadixAddress256
    
    public var root: Root { return rawRoot }
    public var keyPaths: Mapping<String, [Path]> { return rawPaths }
    
    public init(root: Root, paths: Mapping<String, [Path]>) {
        self.rawRoot = root
        self.rawPaths = paths
    }
}

extension RT256: RGRT {
    public func decodeKey(_ symbols: [String]) -> [Bool]? { return symbols.map { $0 == "1" ? true : false } }
    public func encodeKey(_ key: [Bool]) -> [String]? { return key.map { $0 == false ? "0" : "1" } }
    public func decodeValue(_ symbols: [String]) -> [Bool]? { return symbols.map { $0 == "1" ? true : false } }
    public func encodeValue(_ value: [Bool]) -> [String]? { return value.map { $0 == false ? "0" : "1" } }
}