import Foundation
import Nimble
import Quick
import CryptoStarterPack
@testable import Regenerate

final class RTOverlaySpec: QuickSpec {
    override func spec() {
        describe("Partial RMT") {
            describe("subscribe") {
                let firstKey = UInt256.max
                let secondKey = UInt256.min
                typealias ChildNodeType = RGScalar256<UInt256>
                typealias ChildStemType = RGCID<ChildNodeType>
                let source = [firstKey: UInt256.min, secondKey: UInt256.max].mapValues { ChildStemType(artifact: ChildNodeType(raw: $0), complete: true)! }
                typealias DictionaryNodeType = RGDictionary256<UInt256, ChildStemType>
                let dictionaryNode = DictionaryNodeType(source)
                typealias DictionaryStemType = RGCID<DictionaryNodeType>
                let dictionaryRoot = DictionaryStemType(artifact: dictionaryNode!)
                it("root should exist and have node info") {
                    expect(dictionaryRoot).toNot(beNil())
                    expect(dictionaryRoot!.contents()).toNot(beNil())
                    expect(dictionaryRoot!.contents()!).toNot(beEmpty())
                }
                typealias PartialDictionaryNodeType = DictionaryOverlay256<UInt256, ChildStemType>
                let emptyPartialDictionaryNode = PartialDictionaryNodeType(digest: dictionaryNode!.core.digest)
                let configuredPartialDictionaryNode = emptyPartialDictionaryNode.targeting([firstKey])!
                typealias PartialDictionaryStemType = RGCID<PartialDictionaryNodeType>
                let emptyPartialDictionaryStem = PartialDictionaryStemType(artifact: configuredPartialDictionaryNode)
                typealias PartialRegenerativeType = RGObject256<PartialDictionaryStemType>
                let emptyPartialRegenerative = PartialRegenerativeType(root: emptyPartialDictionaryStem!)
                it("should have no dictionary node information") {
                    expect(emptyPartialRegenerative.root.artifact).toNot(beNil())
                    expect(emptyPartialRegenerative.root.artifact!.contents()).toNot(beNil())
                    expect(emptyPartialRegenerative.root.artifact!.contents()!).to(beEmpty())
                }
                let regeneratedPartialDictionary = emptyPartialRegenerative.capture(info: dictionaryRoot!.contents()!)
                it("should be regenerated, but contain only 1 key value tuple for dictionary") {
                    expect(regeneratedPartialDictionary).toNot(beNil())
                    expect(regeneratedPartialDictionary!.root.artifact).toNot(beNil())
                    expect(regeneratedPartialDictionary!.root.artifact!.mapping.count).to(equal(1))
                    expect(regeneratedPartialDictionary!.complete()).to(beTrue())
                }
            }
            describe("subscribe all") {
                let superKey = "animals/"
                let targetKey = superKey + "cats/"
                let notCats = "dogs/"
                let firstKey = superKey + notCats + "1"
                let secondKey = targetKey + "2"
                let thirdKey =  targetKey + "3"
                let fourthKey = targetKey + "4"
                typealias ChildNodeType = RGScalar256<String>
                typealias ChildStemType = RGCID<ChildNodeType>
                let source = [firstKey: "coyote", secondKey: "tiger", thirdKey: "lion", fourthKey: "liger"].mapValues { ChildStemType(artifact: ChildNodeType(raw: $0), complete: true)! }
                typealias DictionaryNodeType = RGDictionary256<String, ChildStemType>
                let dictionaryNode = DictionaryNodeType(source)
                typealias DictionaryStemType = RGCID<DictionaryNodeType>
                let dictionaryRoot = DictionaryStemType(artifact: dictionaryNode!)
                it("root should exist and have node info") {
                    expect(dictionaryRoot).toNot(beNil())
                    expect(dictionaryRoot!.contents()).toNot(beNil())
                    expect(dictionaryRoot!.contents()!).toNot(beEmpty())
                }
                typealias PartialDictionaryNodeType = DictionaryOverlay256<String, ChildStemType>
                let emptyPartialDictionaryNode = PartialDictionaryNodeType(digest: dictionaryNode!.core.digest)
                let configuredPartialDictionaryNode = emptyPartialDictionaryNode.masking([targetKey])!
                typealias PartialDictionaryStemType = RGCID<PartialDictionaryNodeType>
                let emptyPartialDictionaryStem = PartialDictionaryStemType(artifact: configuredPartialDictionaryNode)
                typealias PartialRegenerativeType = RGObject256<PartialDictionaryStemType>
                let emptyPartialRegenerative = PartialRegenerativeType(root: emptyPartialDictionaryStem!)
                it("should have no dictionary node information") {
                    expect(emptyPartialRegenerative.root.artifact).toNot(beNil())
                    expect(emptyPartialRegenerative.root.artifact!.contents()).toNot(beNil())
                    expect(emptyPartialRegenerative.root.artifact!.contents()!).to(beEmpty())
                }
                let regeneratedPartialDictionary = emptyPartialRegenerative.capture(info: dictionaryRoot!.contents()!)
                it("should be regenerated, and contain 3 key value tuples, tiger, lions, and ligers as dictionary values") {
                    expect(regeneratedPartialDictionary).toNot(beNil())
                    expect(regeneratedPartialDictionary!.root.artifact).toNot(beNil())
                    expect(regeneratedPartialDictionary!.root.artifact!.mapping.count).to(equal(3))
                    expect(regeneratedPartialDictionary!.root.artifact!.mapping.keys.contains(firstKey)).to(beFalse())
                    expect(regeneratedPartialDictionary!.root.artifact!.mapping.keys.contains(secondKey)).to(beTrue())
                    expect(regeneratedPartialDictionary!.root.artifact!.mapping.keys.contains(thirdKey)).to(beTrue())
                    expect(regeneratedPartialDictionary!.root.artifact!.mapping.keys.contains(fourthKey)).to(beTrue())
                    expect(regeneratedPartialDictionary!.complete()).to(beTrue())
                }
            }
        }
    }
}
