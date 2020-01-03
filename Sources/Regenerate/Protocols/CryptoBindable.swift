import Foundation
import AwesomeDictionary
import AwesomeTrie

public protocol CryptoBindable {
    func contents(previousKey: Data?, keys: Mapping<Data, Data>) -> Mapping<Data, Data>
	func missing(prefix: [String]) -> Mapping<Data, [[String]]>
    func capture(digestString: Data, content: Data, at route: [String], prefix: [String], previousKey: Data?, keys: Mapping<Data, Data>) -> (Self, Mapping<Data, [[String]]>)?
	func targeting(_ targets: TrieSet<String>, prefix: [String]) -> (Self, Mapping<Data, [[String]]>)
	func masking(_ masks: TrieSet<String>, prefix: [String]) -> (Self, Mapping<Data, [[String]]>)
	func mask(prefix: [String]) -> (Self, Mapping<Data, [[String]]>)
	func target(prefix: [String]) -> (Self, Mapping<Data, [[String]]>)
    func encrypt(allKeys: CoveredTrie<String, Data>, commonIv: Data, keyRoot: Bool) -> Self?
	func isComplete() -> Bool
	func empty() -> Self
}
