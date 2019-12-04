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
			typealias DictionaryNodeType = Dictionary256<UInt256, Address<ChildNodeType>>
			typealias NestedDictionaryNodeType = Dictionary256<UInt256, Address<DictionaryNodeType>>
			typealias RegenerativeNestedDictionaryType = RGObject<Address<NestedDictionaryNodeType>>

			let firstKey = UInt256(0)
			let secondKey = UInt256(1)
            let thirdKey = UInt256(3)
            let fourthKey = UInt256(4)
            
			let firstNode = ChildNodeType(scalar: UInt256.min)
			let secondNode = ChildNodeType(scalar: UInt256.max)
            let thirdNode = ChildNodeType(scalar: UInt256.min)
            let fourthNode = ChildNodeType(scalar: UInt256.min)
            
            let dictionary =
                [firstKey: DictionaryNodeType(da: [firstKey: firstNode,
                                                   secondKey: secondNode])!,
                 secondKey: DictionaryNodeType(da: [thirdKey: thirdNode,
                                                    fourthKey: fourthNode])!]

            let nestedDictionaryNode = NestedDictionaryNodeType(da: dictionary)!
			let regenerativeDictionary = RegenerativeNestedDictionaryType(artifact: nestedDictionaryNode)!
            
			let targets = TrieSet<String>().adding([firstKey.toString(), firstKey.toString()]).adding([secondKey.toString(), fourthKey.toString()])
            
            let cutRegenerativeDictionary = regenerativeDictionary.cuttingAllNodes().targeting(targets).0
            let regeneratedDictionary = cutRegenerativeDictionary.capture(info: Dictionary(uniqueKeysWithValues: regenerativeDictionary.contents().elements()))
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
