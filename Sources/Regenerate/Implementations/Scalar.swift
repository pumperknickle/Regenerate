import Foundation
import Bedrock
import CryptoStarterPack

public struct Scalar<T: Codable>: Codable {
    private let rawScalar: T!
}

extension Scalar: RGScalar {
    public var scalar: T! { return rawScalar }
    public init(scalar: T) { self.rawScalar = scalar }
}

public extension Scalar where T == [Bool] {
    func toBoolArray() -> [Bool] {
        return scalar
    }
    
    init?(raw: [Bool]) {
        rawScalar = raw
    }
}
