import Foundation
import AwesomeDictionary
import AwesomeTrie

public protocol CryptoBindable {
    func contents(previousKey: Data?, keys: Mapping<Data, Data>) -> Mapping<String, Data>
	func missing(prefix: [String]) -> Mapping<String, [[String]]>
    func capture(digestString: String, content: Data, at route: [String], prefix: [String], previousKey: Data?, keys: Mapping<Data, Data>) -> (Self, Mapping<String, [[String]]>)?
	func targeting(_ targets: TrieSet<String>, prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func masking(_ masks: TrieSet<String>, prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func mask(prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func target(prefix: [String]) -> (Self, Mapping<String, [[String]]>)
    func encrypt(allKeys: CoveredTrie<String, Data>, commonIv: Data, keyRoot: Bool) -> Self?
	func isComplete() -> Bool
	func empty() -> Self
}
