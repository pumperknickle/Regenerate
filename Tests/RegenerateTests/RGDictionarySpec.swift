import AwesomeDictionary
import AwesomeTrie
import Bedrock
import CryptoStarterPack
import Foundation
import Nimble
import Quick
@testable import Regenerate

final class RGDictionarySpec: QuickSpec {
    override func spec() {
        describe("Dictionary") {
            // Describe Data Type
            // 2D Dictionary
            typealias ChildNodeType = Scalar<UInt256>
            typealias DictionaryNodeType = Dictionary256<UInt256, Address<ChildNodeType>>
            typealias NestedDictionaryNodeType = Dictionary256<UInt256, Address<DictionaryNodeType>>
            typealias RegenerativeNestedDictionaryType = RGObject<Address<NestedDictionaryNodeType>>

            // Type of Cryptographic Hash
            typealias Digest = RegenerativeNestedDictionaryType.Root.Digest

            // Input Data
            let firstKey = UInt256(0)
            let secondKey = UInt256(1)
            let thirdKey = UInt256(3)
            let fourthKey = UInt256(4)

            // Initialize Data Structure
            let dictionary = NestedDictionaryNodeType(da:
                [firstKey: DictionaryNodeType(da:
                    [firstKey: ChildNodeType(scalar: UInt256.min),
                     secondKey: ChildNodeType(scalar: UInt256.max)])!,
                 secondKey: DictionaryNodeType(da:
                    [thirdKey: ChildNodeType(scalar: UInt256.min),
                     fourthKey: ChildNodeType(scalar: UInt256.min)])!])

            let regenerativeDictionary = RegenerativeNestedDictionaryType(artifact: dictionary)!

            // Extract Node Information
            let serializedNodeInfo = regenerativeDictionary.contents().values()

            // Query given a Hash
            let emptyObject = regenerativeDictionary.cuttingAllNodes()
            let queriedObject = emptyObject.query("{ \(firstKey.toString()) { \(firstKey.toString()) },  \(secondKey.toString()) { \(fourthKey.toString()) }} ")!
            let regenerated = queriedObject.capture(info: serializedNodeInfo)

            it("partial regeneration") {
                expect(regenerated).toNot(beNil())
                expect(regenerated!.root.artifact!.children.elements().count).to(equal(2))
                expect(regenerated!.root.artifact!.children.keys()).to(contain(firstKey.toString()))
                expect(regenerated!.root.artifact!.children.keys()).to(contain(secondKey.toString()))
                expect(regenerated!.root.artifact!.children.values().map { $0.artifact!.children.values().contains(where: { !$0.complete }) }).toNot(contain(true))
            }
        }
    }
}
