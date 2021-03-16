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
    enum CodingKeys: String, CodingKey {
        case scalar
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        rawScalar = try values.decode(T.self, forKey: .scalar)
        return
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawScalar, forKey: .scalar)
        return
    }
}
