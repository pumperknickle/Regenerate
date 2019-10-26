import Foundation
import Nimble
import Quick
import CryptoStarterPack
import Bedrock
import AwesomeTrie
import AwesomeDictionary
@testable import Regenerate

final class RGArraySpec: QuickSpec {
	override func spec() {
		describe("Array") {
			typealias ChildNodeType = Scalar<UInt256>
			typealias ChildStemType = Address<ChildNodeType>
			typealias ArrayNodeType = Array256<ChildStemType>
			typealias ArrayStemType = Address<ArrayNodeType>
			typealias NestedArrayNodeType = Array256<ArrayStemType>
			typealias NestedArrayStemType = Address<NestedArrayNodeType>
			typealias RegenerativeNestedArrayType = RGObject<NestedArrayStemType>
			
			// array 0-0
			let firstNode = ChildNodeType(raw: UInt256.min)
			let secondNode = ChildNodeType(raw: UInt256.max)
			let firstStem = ChildStemType(artifact: firstNode, complete: true)
			let secondStem = ChildStemType(artifact: secondNode, complete: true)
			let arrayNode1 = ArrayNodeType([firstStem!, secondStem!])!
			let arrayStem1 = ArrayStemType(artifact: arrayNode1, complete: true)

			// array 0-1
			let thirdNode = ChildNodeType(raw: UInt256(109303931))
			let fourthNode = ChildNodeType(raw: UInt256(10922))
			let thirdStem = ChildStemType(artifact: thirdNode, complete: true)
			let fourthStem = ChildStemType(artifact: fourthNode, complete: true)
			let arrayNode2 = ArrayNodeType([thirdStem!, fourthStem!])!
			let arrayStem2 = ArrayStemType(artifact: arrayNode2, complete: true)

			let nestedArrayNode = NestedArrayNodeType([arrayStem1!, arrayStem2!])!
			let nestedArrayStem = NestedArrayStemType(artifact: nestedArrayNode, complete: true)
			let regenerativeArray = RegenerativeNestedArrayType(root: nestedArrayStem!)
			let targets = TrieSet<String>().adding([NestedArrayStemType.Digest(0).toString(), ArrayStemType.Digest(0).toString()]).adding([NestedArrayStemType.Digest(0).toString(), ArrayStemType.Digest(1).toString()])
			let cutRegenerativeArray = regenerativeArray.cuttingAllNodes().targeting(targets)
			let regeneratedArray = cutRegenerativeArray.0.capture(info: Dictionary(uniqueKeysWithValues: regenerativeArray.contents().elements()))
			it("partial regeneration") {
				expect(regeneratedArray).toNot(beNil())
				expect(regeneratedArray!.root.artifact!.children.elements().count).to(equal(1))
			
			}
		}
	}
}
