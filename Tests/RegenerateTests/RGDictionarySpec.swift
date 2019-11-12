import Foundation
import Nimble
import Quick
import CryptoStarterPack
import Bedrock
import AwesomeTrie
import AwesomeDictionary
@testable import Regenerate

final class RGDictionarySpec: QuickSpec {
	override func spec() {
		describe("Dictionary") {
			typealias ChildNodeType = Scalar<UInt256>
			typealias ChildStemType = Address<ChildNodeType>
			typealias DictionaryNodeType = Dictionary256<UInt256, ChildStemType>
			typealias DictionaryStemType = Address<DictionaryNodeType>
			typealias NestedDictionaryNodeType = Dictionary256<UInt256, DictionaryStemType>
			typealias NestedDictionaryStemType = Address<NestedDictionaryNodeType>
			typealias RegenerativeNestedDictionaryType = RGObject<NestedDictionaryStemType>

			// dictionary 0-0
			let firstKey = UInt256(0)
			let secondKey = UInt256(1)
			let firstNode = ChildNodeType(raw: UInt256.min)
			let secondNode = ChildNodeType(raw: UInt256.max)
			let firstStem = ChildStemType(artifact: firstNode, symmetricKeyHash: nil, complete: true)
			let secondStem = ChildStemType(artifact: secondNode, symmetricKeyHash: nil, complete: true)
			let mapping = Mapping<UInt256, ChildStemType>().setting(key: firstKey, value: firstStem!).setting(key: secondKey, value: secondStem!)
			let dictionaryNode1 = DictionaryNodeType(mapping)!
			let dictionaryStem1 = DictionaryStemType(artifact: dictionaryNode1, symmetricKeyHash: nil, complete: true)
			
			// dictionary 0-1
			let thirdKey = UInt256(3)
			let fourthKey = UInt256(4)
			let thirdNode = ChildNodeType(raw: UInt256.min)
			let fourthNode = ChildNodeType(raw: UInt256.min)
			let thirdStem = ChildStemType(artifact: thirdNode, symmetricKeyHash: nil, complete: true)
			let fourthStem = ChildStemType(artifact: fourthNode, symmetricKeyHash: nil, complete: true)
			let secondMapping = Mapping<UInt256, ChildStemType>().setting(key: thirdKey, value: thirdStem!).setting(key: fourthKey, value: fourthStem!)
			let dictionaryNode2 = DictionaryNodeType(secondMapping)!
			let dictionaryStem2 = DictionaryStemType(artifact: dictionaryNode2, symmetricKeyHash: nil, complete: true)

			let parentMapping = Mapping<UInt256, DictionaryStemType>().setting(key: firstKey, value: dictionaryStem1!).setting(key: secondKey, value: dictionaryStem2!)
			let nestedDictionaryNode = NestedDictionaryNodeType(parentMapping)!
			let nestedDictionaryStem = NestedDictionaryStemType(artifact: nestedDictionaryNode, symmetricKeyHash: nil, complete: true)
			let regenerativeDictionary = RegenerativeNestedDictionaryType(root: nestedDictionaryStem!)
			let targets = TrieSet<String>().adding([firstKey.toString(), firstKey.toString()]).adding([secondKey.toString(), fourthKey.toString()])
			let cutRegenerativeDictionary = regenerativeDictionary.cuttingAllNodes().targeting(targets)
			let regeneratedDictionary = cutRegenerativeDictionary.0.capture(info: Dictionary(uniqueKeysWithValues: regenerativeDictionary.contents(previousKey: nil, keys: TrieMapping<Bool, [Bool]>()).elements()), previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
			it("partial regeneration") {
				expect(regeneratedDictionary).toNot(beNil())
				expect(regeneratedDictionary!.root.artifact!.children.elements().count).to(equal(2))
				expect(regeneratedDictionary!.root.artifact!.children.keys()).to(contain(firstKey.toString()))
				expect(regeneratedDictionary!.root.artifact!.children.keys()).to(contain(secondKey.toString()))
				expect(regeneratedDictionary!.root.artifact!.children.values().map { $0.artifact!.children.values().contains(where: { !$0.complete }) }).toNot(contain(true))
			}
		}
	}
}
