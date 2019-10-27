import Foundation
import AwesomeDictionary
import AwesomeTrie

public protocol CryptoBindable {
	func contents() -> Mapping<String, [Bool]>
	func missing(prefix: [String]) -> Mapping<String, [[String]]>
	func capture(digestString: String, content: [Bool], at route: [String], prefix: [String]) -> (Self, Mapping<String, [[String]]>)?
	func targeting(_ targets: TrieSet<String>, prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func masking(_ masks: TrieSet<String>, prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func mask(prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func target(prefix: [String]) -> (Self, Mapping<String, [[String]]>)
	func isComplete() -> Bool
	func empty() -> Self
	func set(key: [Bool], iv: [Bool]) -> Self?
}
