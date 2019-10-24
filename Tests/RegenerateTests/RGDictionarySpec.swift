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
			typealias ChildNodeType = RGScalar256<UInt256>
			typealias ChildStemType = RGCID<ChildNodeType>
			typealias DictionaryNodeType = RGDictionary256<UInt256, ChildStemType>
			typealias DictionaryStemType = RGCID<DictionaryNodeType>
			typealias NestedDictionaryNodeType = RGDictionary256<UInt256, DictionaryStemType>
			typealias NestedDictionaryStemType = RGCID<NestedDictionaryNodeType>
			typealias RegenerativeNestedDictionaryType = RGObject256<NestedDictionaryStemType>

			// dictionary 0-0
			let firstKey = UInt256(0)
			let secondKey = UInt256(1)
			let firstNode = ChildNodeType(raw: UInt256.min)
			let secondNode = ChildNodeType(raw: UInt256.max)
			let firstStem = ChildStemType(artifact: firstNode, complete: true)
			let secondStem = ChildStemType(artifact: secondNode, complete: true)
			let mapping = Mapping<UInt256, ChildStemType>().setting(key: firstKey, value: firstStem!).setting(key: secondKey, value: secondStem!)
			let dictionaryNode1 = DictionaryNodeType(mapping)!
			let dictionaryStem1 = DictionaryStemType(artifact: dictionaryNode1, complete: true)
			
			// dictionary 0-1
			let thirdKey = UInt256(3)
			let fourthKey = UInt256(4)
			let thirdNode = ChildNodeType(raw: UInt256.min)
			let fourthNode = ChildNodeType(raw: UInt256.min)
			let thirdStem = ChildStemType(artifact: thirdNode, complete: true)
			let fourthStem = ChildStemType(artifact: fourthNode, complete: true)
			let secondMapping = Mapping<UInt256, ChildStemType>().setting(key: thirdKey, value: thirdStem!).setting(key: fourthKey, value: fourthStem!)
			let dictionaryNode2 = DictionaryNodeType(secondMapping)!
			let dictionaryStem2 = DictionaryStemType(artifact: dictionaryNode2, complete: true)

			let parentMapping = Mapping<UInt256, DictionaryStemType>().setting(key: firstKey, value: dictionaryStem1!).setting(key: secondKey, value: dictionaryStem2!)
			let nestedDictionaryNode = NestedDictionaryNodeType(parentMapping)!
			let nestedDictionaryStem = NestedDictionaryStemType(artifact: nestedDictionaryNode, complete: true)
			let regenerativeDictionary = RegenerativeNestedDictionaryType(root: nestedDictionaryStem!)
			let cutRegenerativeDictionary = regenerativeDictionary.cuttingAllNodes().targeting(TrieSet<String>().adding([firstKey.toString(), firstKey.toString()]))
			let regeneratedDictionary = cutRegenerativeDictionary.0.capture(info: Dictionary(uniqueKeysWithValues: regenerativeDictionary.contents()!.elements()))
			it("should get just 1 subchild") {
				expect(regeneratedDictionary).toNot(beNil())
				expect(regeneratedDictionary!.root.artifact!.children.elements().count).to(equal(1))
			}
		}
	}
}



//import Foundation
//import Nimble
//import Quick
//import CryptoStarterPack
//import Bedrock
//@testable import Regenerate
//
//final class RGDictionarySpec: QuickSpec {
//    override func spec() {
//        describe("RGDictionary") {
//            typealias ChildNodeType = RGScalar256<UInt256>
//            let firstKey = UInt256(0)
//            let secondKey = UInt256(1)
//            let firstNode = ChildNodeType(raw: UInt256.min)
//            let secondNode = ChildNodeType(raw: UInt256.max)
//            typealias ChildStemType = RGCID<ChildNodeType>
//            let firstStem = ChildStemType(artifact: firstNode, complete: true)
//            let secondStem = ChildStemType(artifact: secondNode, complete: true)
//            typealias DictionaryNodeType = RGDictionary256<UInt256, ChildStemType>
//            let dictionaryNode = DictionaryNodeType([firstKey: firstStem!, secondKey: secondStem!])
//            it("should create with raw dictionary") {
//                expect(dictionaryNode).toNot(beNil())
//                expect(dictionaryNode!.mapping.count).to(equal(2))
//            }
//            it("should create same dictionary when setting") {
//                let emptyDictionary = DictionaryNodeType([:])
//                expect(emptyDictionary).toNot(beNil())
//                let finalDictionary = emptyDictionary!.setting(key: firstKey, to: firstStem!)!.setting(key: secondKey, to: secondStem!)
//                expect(finalDictionary).toNot(beNil())
//                expect(finalDictionary!.toBoolArray()).to(equal(dictionaryNode!.toBoolArray()))
//            }
//            typealias DictionaryStemType = RGCID<DictionaryNodeType>
//            let dictionaryRoot = DictionaryStemType(artifact: dictionaryNode!)
//            it("should have node content and not be nil") {
//                expect(dictionaryRoot).toNot(beNil())
//                expect(dictionaryRoot!.contents()).toNot(beNil())
//                expect(dictionaryRoot!.contents()!.elements()).toNot(beEmpty())
//            }
//            typealias RegenerativeDictionaryType = RGObject256<DictionaryStemType>
//            let regenerativeDictionary = RegenerativeDictionaryType(root: dictionaryRoot!)
//            it("can extract node information") {
//                expect(regenerativeDictionary.contents()).toNot(beNil())
//                expect(regenerativeDictionary.contents()!.elements()).toNot(beEmpty())
//            }
//            let cutRegenerativeDictionary = regenerativeDictionary.cuttingAllNodes()
//            it("can have just a digest") {
//                expect(cutRegenerativeDictionary.root.digest).to(equal(regenerativeDictionary.root.digest))
//                expect(cutRegenerativeDictionary.contents()).toNot(beNil())
//                expect(cutRegenerativeDictionary.contents()!.elements()).to(beEmpty())
//            }
//            let regeneratedDictionary = cutRegenerativeDictionary.capture(info: Dictionary(uniqueKeysWithValues: regenerativeDictionary.contents()!.elements()))
//            it("can regenerate"){
//                expect(regeneratedDictionary).toNot(beNil())
//                expect(regeneratedDictionary!.complete()).to(beTrue())
//                expect(regeneratedDictionary!.contents()).toNot(beNil())
//                expect(regeneratedDictionary!.contents()!.elements().count).to(equal(dictionaryRoot!.contents()!.elements().count))
//                expect(regeneratedDictionary!.root.digest).to(equal(regenerativeDictionary.root.digest))
//            }
//            describe("2D RGDictionaries or nested RGDictionaries") {
//                typealias NestedDictionaryNodeType = RGDictionary256<UInt256, DictionaryStemType>
//                let nestedDictionaryNode = NestedDictionaryNodeType([UInt256(0): dictionaryRoot!])
//                it("node nested create") {
//                    expect(nestedDictionaryNode).toNot(beNil())
//                    expect(nestedDictionaryNode!.isComplete()).to(beTrue())
//                }
//                typealias NestedDictionaryStemType = RGCID<NestedDictionaryNodeType>
//                let nestedDictionaryRoot = NestedDictionaryStemType(artifact: nestedDictionaryNode!, complete: true)
//                it("root nested create") {
//                    expect(nestedDictionaryRoot).toNot(beNil())
//                }
//                typealias RegenerativeNestedDictionaryType = RGObject256<NestedDictionaryStemType>
//                let nestedRegenerative = RegenerativeNestedDictionaryType(root: nestedDictionaryRoot!)
//                it("should have all node contents") {
//                    expect(nestedRegenerative.complete()).to(beTrue())
//                    expect(nestedRegenerative.contents()).toNot(beNil())
//                    expect(nestedRegenerative.contents()!.elements()).toNot(beEmpty())
//                }
//                let cutNestedRegenerative = nestedRegenerative.cuttingAllNodes()
//                let regeneratedNestedDictionary = cutNestedRegenerative.capture(info: Dictionary(uniqueKeysWithValues: nestedRegenerative.contents()!.elements()))
//                it("can be regenerated fully and completely, bit for bit") {
//                    expect(regeneratedNestedDictionary).toNot(beNil())
//                    expect(regeneratedNestedDictionary!.complete()).to(beTrue())
//                }
//            }
//        }
//    }
//}
//
