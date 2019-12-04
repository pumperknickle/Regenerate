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
			typealias LeafNode = Scalar<UInt256>
			typealias ArrayNode = Array256<Address<LeafNode>>
			typealias NestedArrayNode = Array256<Address<ArrayNode>>
			typealias RegenerativeNestedArrayType = RGObject<Address<NestedArrayNode>>

			let firstNode = LeafNode(scalar: UInt256.min)
			let secondNode = LeafNode(scalar: UInt256.max)
			let thirdNode = LeafNode(scalar: UInt256(109303931))
			let fourthNode = LeafNode(scalar: UInt256(10922))

			let nestedArrayNode =
                NestedArrayNode(artifacts:
                    [ArrayNode(artifacts: [firstNode,
                                           secondNode])!,
                     ArrayNode(artifacts: [thirdNode,
                                           fourthNode])!])!
            
			let regenerativeArray = RegenerativeNestedArrayType(artifact: nestedArrayNode)!
            
            let targets = TrieSet<String>()
                .adding([
                    RegenerativeNestedArrayType.Root.Digest(0).toString(),
                    NestedArrayNode.Value.Digest(0).toString()])
                .adding([
                    RegenerativeNestedArrayType.Root.Digest(0).toString(),
                    NestedArrayNode.Value.Digest(1).toString()])
            
            let cutRegenerativeArray = regenerativeArray.cuttingAllNodes().targeting(targets).0
            
            let rawInformation = Dictionary(uniqueKeysWithValues: regenerativeArray.contents().elements())
            
            let regeneratedArray = cutRegenerativeArray.capture(info: rawInformation)
            
			it("partial regeneration") {
				expect(regeneratedArray).toNot(beNil())
				expect(regeneratedArray!.root.artifact!.children.elements().count).to(equal(1))
			}
		}
	}
}
