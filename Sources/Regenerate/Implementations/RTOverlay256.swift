import Foundation
import CryptoStarterPack

public struct RTOverlay256<Key: BinaryEncodable, Value: BinaryEncodable>: Codable {
    private let rawRoot: StemOverlay256!
    private let rawPaths: [UInt256: [[String]]]!
}

extension RTOverlay256: RGObject {
    public typealias Root = StemOverlay256
    
    public var root: StemOverlay256 { return rawRoot }
    public var keyPaths: [UInt256 : [Path]] { return rawPaths }
    
    public init(root: StemOverlay256, paths: [UInt256 : [Path]]) {
        self.rawRoot = root
        self.rawPaths = paths
    }
}

extension RTOverlay256: RGRT {
    public func decodeKey(_ symbols: [Bool]) -> [Bool]? { return symbols }
    public func encodeKey(_ key: [Bool]) -> [Bool]? { return key }
    public func decodeValue(_ symbols: [Bool]) -> [Bool]? { return symbols }
    public func encodeValue(_ value: [Bool]) -> [Bool]? { return value }
}

extension RTOverlay256: RTOverlay { }
