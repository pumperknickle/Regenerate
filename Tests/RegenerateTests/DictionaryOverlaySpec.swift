import Foundation
import Nimble
import Quick
import CryptoStarterPack
@testable import Regenerate

final class DictionaryOverlaySpec: QuickSpec {
    override func spec() {
        describe("Partial Dictionary Merkle Structure") {
            describe("target keys") {
                typealias ChildNodeType = RGScalar256<UInt256>
                typealias ChildCIDType = RGCID<ChildNodeType>
                typealias DictionaryNodeType = RGDictionary256<UInt256, ChildCIDType>
                typealias DictionaryCIDType = RGCID<DictionaryNodeType>
                typealias DictionaryOverlayNodeType = DictionaryOverlay256<UInt256, ChildCIDType>
                typealias DictionaryOverlayCIDType = RGCID<DictionaryOverlayNodeType>
                typealias DictionaryOverlayObjectType = RGObject256<DictionaryOverlayCIDType>

                let firstKey = UInt256.max
                let secondKey = UInt256.min
                let source = [firstKey: UInt256.min, secondKey: UInt256.max].mapValues { ChildCIDType(artifact: ChildNodeType(raw: $0), complete: true)! }
                let dictionaryNode = DictionaryNodeType(source)
                let dictionaryRoot = DictionaryCIDType(artifact: dictionaryNode!)
                
                it("root should exist and have node info") {
                    expect(dictionaryRoot).toNot(beNil())
                    expect(dictionaryRoot!.contents()).toNot(beNil())
                    expect(dictionaryRoot!.contents()!).toNot(beEmpty())
                }
                let overlayRoot = DictionaryOverlayNodeType.CoreRootType(digest: dictionaryNode!.core.root.digest)
                let emptyDictionaryOverlayNode = DictionaryOverlayNodeType(root: overlayRoot)
                let configuredDictionaryOverlayNode = emptyDictionaryOverlayNode.targeting([firstKey])!
                let emptyDictionaryOverlayCID = DictionaryOverlayCIDType(artifact: configuredDictionaryOverlayNode)
                let emptyDictionaryOverlayObject = DictionaryOverlayObjectType(root: emptyDictionaryOverlayCID!)
                it("shouldn't have any information since it was created with just a digest and length") {
                    expect(emptyDictionaryOverlayObject.root.artifact).toNot(beNil())
                    expect(emptyDictionaryOverlayObject.root.artifact!.contents()).toNot(beNil())
                    expect(emptyDictionaryOverlayObject.root.artifact!.contents()!).to(beEmpty())
                }
                let regenerativeDictionaryOverlayObject = emptyDictionaryOverlayObject.capture(info: dictionaryRoot!.contents()!)
                it("should be regenerated, but contain only 1 key value tuple for dictionary") {
                    expect(regenerativeDictionaryOverlayObject).toNot(beNil())
                    expect(regenerativeDictionaryOverlayObject!.root.artifact).toNot(beNil())
                    expect(regenerativeDictionaryOverlayObject!.root.artifact!.mapping.count).to(equal(1))
                    expect(regenerativeDictionaryOverlayObject!.complete()).to(beFalse())
                }
            }
            describe("mask") {
                typealias ChildNodeType = RGScalar256<String>
                typealias ChildCIDType = RGCID<ChildNodeType>
                typealias DictionaryNodeType = RGDictionary256<String, ChildCIDType>
                typealias DictionaryCIDType = RGCID<DictionaryNodeType>
                typealias DictionaryOverlayNodeType = DictionaryOverlay256<String, ChildCIDType>
                typealias DictionaryOverlayCIDType = RGCID<DictionaryOverlayNodeType>
                typealias DictionaryOverlayObjectType = RGObject256<DictionaryOverlayCIDType>

                let superKey = "animals/"
                let targetKey = superKey + "cats/"
                let notCats = "dogs/"
                let firstKey = superKey + notCats + "1"
                let secondKey = targetKey + "2"
                let thirdKey =  targetKey + "3"
                let fourthKey = targetKey + "4"
                
                let source = [firstKey: "coyote", secondKey: "tiger", thirdKey: "lion", fourthKey: "liger"].mapValues { ChildCIDType(artifact: ChildNodeType(raw: $0), complete: true)! }
                
                let dictionaryNode = DictionaryNodeType(source)
                let dictionaryRoot = DictionaryCIDType(artifact: dictionaryNode!)

                it("root should exist and have node info") {
                    expect(dictionaryRoot).toNot(beNil())
                    expect(dictionaryRoot!.contents()).toNot(beNil())
                    expect(dictionaryRoot!.contents()!).toNot(beEmpty())
                }
                let overlayRoot = DictionaryOverlayNodeType.CoreRootType(digest: dictionaryNode!.core.root.digest)
                let emptyDictionaryOverlayNode = DictionaryOverlayNodeType(root: overlayRoot)
                let configuredDictionaryOverlayNode = emptyDictionaryOverlayNode.masking([targetKey])!
                let emptyDictionaryOverlayCID = DictionaryOverlayCIDType(artifact: configuredDictionaryOverlayNode)
                let emptyDictionaryOverlayObject = DictionaryOverlayObjectType(root: emptyDictionaryOverlayCID!)
                it("should have no dictionary node information") {
                    expect(emptyDictionaryOverlayObject.root.artifact).toNot(beNil())
                    expect(emptyDictionaryOverlayObject.root.artifact!.contents()).toNot(beNil())
                    expect(emptyDictionaryOverlayObject.root.artifact!.contents()!).to(beEmpty())
                }
                let regeneratedDictionaryOverlayObject = emptyDictionaryOverlayObject.capture(info: dictionaryRoot!.contents()!)
                it("should be regenerated, and contain 3 key value tuples, tiger, lions, and ligers as dictionary values") {
                    expect(regeneratedDictionaryOverlayObject).toNot(beNil())
                    expect(regeneratedDictionaryOverlayObject!.root.artifact).toNot(beNil())
                    expect(regeneratedDictionaryOverlayObject!.root.artifact!.mapping.count).to(equal(3))
                    expect(regeneratedDictionaryOverlayObject!.root.artifact!.mapping.keys.contains(firstKey)).to(beFalse())
                    expect(regeneratedDictionaryOverlayObject!.root.artifact!.mapping.keys.contains(secondKey)).to(beTrue())
                    expect(regeneratedDictionaryOverlayObject!.root.artifact!.mapping.keys.contains(thirdKey)).to(beTrue())
                    expect(regeneratedDictionaryOverlayObject!.root.artifact!.mapping.keys.contains(fourthKey)).to(beTrue())
                    expect(regeneratedDictionaryOverlayObject!.complete()).to(beFalse())
                }
            }
        }
    }
}
