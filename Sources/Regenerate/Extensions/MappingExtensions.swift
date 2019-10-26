import Foundation
import AwesomeDictionary

public extension Mapping where Value == [[String]] {
    static func + (lhs: Mapping<Key, Value>, rhs: Mapping<Key, Value>) -> Mapping<Key, Value> {
        return rhs.elements().lazy.reduce(lhs) { (result, entry) -> Mapping<Key, Value> in
            guard let current = result[entry.0] else { return result.setting(key: entry.0, value: entry.1) }
            return result.setting(key: entry.0, value: entry.1 + current)
        }
    }
}
