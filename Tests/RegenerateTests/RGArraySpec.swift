import AwesomeDictionary
import AwesomeTrie
import Bedrock
import CryptoStarterPack
import Foundation
import Nimble
import Quick
@testable import Regenerate

final class RGArraySpec: QuickSpec {
    override func spec() {
        describe("Array") {
            // Describe Data Types
            // 2D Array
            typealias LeafNode = Scalar<String>
            typealias ArrayNode = Array256<Address<LeafNode>>
            typealias NestedArrayNode = Array256<Address<ArrayNode>>
            typealias RegenerativeNestedArrayType = RGObject<Address<NestedArrayNode>>

            // Type of Cryptographic Hash
            typealias Digest = RegenerativeNestedArrayType.Root.Digest

            // Input Data
            let firstNode = LeafNode(scalar: "1")
            let secondNode = LeafNode(scalar: "2")
            let thirdNode = LeafNode(scalar: "3")
            let fourthNode = LeafNode(scalar: "4")

            // Initialize Data Structure
            let nestedArrayNode =
                NestedArrayNode(artifacts:
                    [ArrayNode(artifacts: [firstNode,
                                           secondNode])!,
                     ArrayNode(artifacts: [thirdNode,
                                           fourthNode])!])!

            let regenerativeArray = RegenerativeNestedArrayType(artifact: nestedArrayNode)!

            // Extract Node Information
            let serializedNodeInfo = regenerativeArray.contents().values()

            // Query given a Hash
            let emptyObject = regenerativeArray.cuttingAllNodes()
            let queriedObject = emptyObject.query("{ \(Digest(0).toString()) { \(Digest(0).toString()), \(Digest(1).toString()) } } ")!
            let regenerated = queriedObject.capture(info: serializedNodeInfo)

            it("regenerates only the queried values!") {
                expect(regenerated).toNot(beNil())
                expect(regenerated!.root.artifact!.children.elements().count).to(equal(1))
                expect(regenerated!.root.artifact!.children.elements().first!.1.artifact!.children.elements().count).to(equal(2))
                expect(emptyObject.complete()).to(equal(true))
            }
        }
    }
}
