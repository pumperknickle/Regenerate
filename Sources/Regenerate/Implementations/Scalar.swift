import Bedrock
import CryptoStarterPack
import Foundation

public struct Scalar<T: DataEncodable> {
    private let rawScalar: T!
}

extension Scalar: RGScalar {
    public var scalar: T! { return rawScalar }
    public init(scalar: T) { rawScalar = scalar }
}

extension Scalar: Codable {
    public init(from decoder: Decoder) throws {
        rawScalar = T(data: Data())
        return
    }
    
    public func encode(to encoder: Encoder) throws {
        return
    }
}
