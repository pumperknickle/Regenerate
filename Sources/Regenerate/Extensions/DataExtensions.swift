import Foundation
import Bedrock
import AwesomeDictionary

public extension Data {
    func convertToStructured<T: DataEncodable>() -> T? {
        return T(data: self)
    }
}

public extension Array where Element == Data {
    func convertToStructured<T: DataEncodable>() -> [T]? {
        guard let firstElement = first else { return [] }
        guard let firstStructured: T = firstElement.convertToStructured() else { return nil }
        guard let children: [T] = Array(dropFirst()).convertToStructured() else { return nil }
        return [firstStructured] + children
    }
}

public extension Set where Element == Data {
    func convertToStructured<T: DataEncodable>() -> Set<T>? {
        guard let result: [T] = Array(self).convertToStructured() else { return nil }
        return Set<T>(result)
    }
}

public extension Mapping where Key == Data {
    func convertToStructured<T: DataEncodable>() -> Mapping<T, Value>? {
        return keys().reduce(Mapping<T, Value>()) { (result, entry) -> Mapping<T, Value>? in
            guard let result = result else { return nil }
            guard let structuredKey: T = entry.convertToStructured() else { return nil }
            guard let val = self[entry] else { return nil }
            return result.setting(key: structuredKey, value: val)
        }
    }
}

public extension Mapping where Key: DataEncodable {
    func convertToData() -> Mapping<Data, Value> {
        return keys().reduce(Mapping<Data, Value>()) { (result, entry) -> Mapping<Data, Value> in
            return result.setting(key: entry.toData(), value: self[entry]!)
        }
    }
}
