import Foundation
import AwesomeDictionary
import AwesomeTrie

public protocol CryptoBindable {
	func contents(prefix: [String]) -> Mapping<String, [Bool]>
	func missing(prefix: [String]) -> Mapping<String, [[String]]>
	func capture(digestString: String, content: [Bool], at route: [String], prefix: [String]) -> (Self, Mapping<String, [[String]]>)?
	func targeting(_ targets: TrieSet<String>, prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func masking(_ masks: TrieSet<String>, prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func mask(prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func target(prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func encrypt(allKeys: CoveredTrie<String, [Bool]>, commonIv: [Bool]) -> Self?
	func isComplete() -> Bool
	func empty() -> Self
}
