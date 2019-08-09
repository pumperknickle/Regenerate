import Foundation
import CryptoStarterPack

public struct RGRT256<Key: BinaryEncodable, Value: BinaryEncodable>: Codable {
    private let rawRoot: Stem256!
    private let rawPaths: [UInt256: [[String]]]!
}

extension RGRT256: RGObject {
    public typealias Root = Stem256
    
    public var root: Stem256 { return rawRoot }
    public var keyPaths: [UInt256 : [[String]]] { return rawPaths }
    
    public init(root: Stem256, paths: [UInt256 : [[String]]]) {
        self.rawRoot = root
        self.rawPaths = paths
    }
}

extension RGRT256: RGRT {
    public func decodeKey(_ symbols: [Bool]) -> [Bool]? { return symbols }
    public func encodeKey(_ key: [Bool]) -> [Bool]? { return key }
    public func decodeValue(_ symbols: [Bool]) -> [Bool]? { return symbols }
    public func encodeValue(_ value: [Bool]) -> [Bool]? { return value }
}
