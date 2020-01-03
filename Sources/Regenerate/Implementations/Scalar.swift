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
