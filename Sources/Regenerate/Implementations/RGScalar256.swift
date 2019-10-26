import Foundation
import Bedrock
import CryptoStarterPack

public struct RGScalar256<T: Codable>: Codable {
    private let rawScalar: T!
}

extension RGScalar256: RGScalar {
    public var scalar: T! { return rawScalar }
    public init(raw: T) { self.rawScalar = raw }
}
