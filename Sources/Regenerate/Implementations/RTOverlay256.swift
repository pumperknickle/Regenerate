import Foundation
import CryptoStarterPack

public struct RTOverlay256<Key: BinaryEncodable, Value: BinaryEncodable>: Codable {
    private let rawRoot: Root!
    private let rawPaths: [Digest: [Path]]!
}

extension RTOverlay256: RGObject {
    public typealias Root = StemOverlay256
    
    public var root: Root { return rawRoot }
    public var keyPaths: [Digest : [Path]] { return rawPaths }
    
    public init(root: Root, paths: [Digest : [Path]]) {
        self.rawRoot = root
        self.rawPaths = paths
    }
}

extension RTOverlay256: RGRT {
    public func decodeKey(_ symbols: [String]) -> [Bool]? { return symbols.map { $0 == "1" ? true : false } }
    public func encodeKey(_ key: [Bool]) -> [String]? { return key.map { $0 == false ? "0" : "1" } }
    public func decodeValue(_ symbols: [String]) -> [Bool]? { return symbols.map { $0 == "1" ? true : false } }
    public func encodeValue(_ value: [Bool]) -> [String]? { return value.map { $0 == false ? "0" : "1" } }
}

extension RTOverlay256: RTOverlay { }
