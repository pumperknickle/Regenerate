import Foundation
import CryptoStarterPack

public struct RGScalar256<T: Codable>: Codable {
    private let rawScalar: T!
}

extension RGScalar256: RGScalar {
    public func pruning() -> RGScalar256<T> { return self }
    public typealias CryptoDelegateType = BaseCrypto
    public typealias Digest = UInt256
    public var scalar: T! { return rawScalar }
    public init(raw: T) { self.rawScalar = raw }
}
