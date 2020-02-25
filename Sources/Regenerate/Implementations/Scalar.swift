import Bedrock
import CryptoStarterPack
import Foundation

public struct Scalar<T: DataEncodable>: Codable {
    private let rawScalar: T!
}

extension Scalar: RGScalar {
    public var scalar: T! { return rawScalar }
    public init(scalar: T) { rawScalar = scalar }
}
