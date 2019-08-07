import Foundation
import Nimble
import Quick
import CryptoStarterPack
@testable import Regenerate

final class RGDictionarySpec: QuickSpec {
    override func spec() {
        describe("RGDictionary") {
            typealias ChildNodeType = RGScalar256<UInt256>
            let firstKey = UInt256(0)
            let secondKey = UInt256(1)
            let firstNode = ChildNodeType(raw: UInt256.min)
            let secondNode = ChildNodeType(raw: UInt256.max)
            typealias ChildStemType = RGCID<ChildNodeType>
            let firstStem = ChildStemType(artifact: firstNode, complete: true)
            let secondStem = ChildStemType(artifact: secondNode, complete: true)
            typealias DictionaryNodeType = RGDictionary256<UInt256, ChildStemType>
            let dictionaryNode = DictionaryNodeType([firstKey: firstStem!, secondKey: secondStem!])
            it("should create with raw dictionary") {
                expect(dictionaryNode).toNot(beNil())
                expect(dictionaryNode!.mapping.count).to(equal(2))
            }
            it("should create same dictionary when setting") {
                let emptyDictionary = DictionaryNodeType([:])
                expect(emptyDictionary).toNot(beNil())
                let finalDictionary = emptyDictionary!.setting(key: firstKey, to: firstStem!)!.setting(key: secondKey, to: secondStem!)
                expect(finalDictionary).toNot(beNil())
                expect(finalDictionary!.hash()).toNot(beNil())
                expect(finalDictionary!.hash()!).to(equal(dictionaryNode!.hash()))
            }
            typealias DictionaryStemType = RGCID<DictionaryNodeType>
            let dictionaryRoot = DictionaryStemType(artifact: dictionaryNode!)
            it("should have node content and not be nil") {
                expect(dictionaryRoot).toNot(beNil())
                expect(dictionaryRoot!.contents()).toNot(beNil())
                expect(dictionaryRoot!.contents()).toNot(beEmpty())
            }
            typealias RegenerativeDictionaryType = RGObject256<DictionaryStemType>
            let regenerativeDictionary = RegenerativeDictionaryType(root: dictionaryRoot!)
            it("can extract node information") {
                expect(regenerativeDictionary.contents()).toNot(beNil())
                expect(regenerativeDictionary.contents()!).toNot(beEmpty())
            }
            let cutRegenerativeDictionary = regenerativeDictionary.cuttingAllNodes()
            it("can have just a digest") {
                expect(cutRegenerativeDictionary.root.digest).to(equal(regenerativeDictionary.root.digest))
                expect(cutRegenerativeDictionary.contents()).toNot(beNil())
                expect(cutRegenerativeDictionary.contents()!).to(beEmpty())
            }
            let regeneratedDictionary = cutRegenerativeDictionary.capture(info: regenerativeDictionary.contents()!)
            it("can regenerate"){
                expect(regeneratedDictionary).toNot(beNil())
                expect(regeneratedDictionary!.complete()).to(beTrue())
                expect(regeneratedDictionary!.contents()).toNot(beNil())
                expect(regeneratedDictionary!.contents()!.count).to(equal(dictionaryRoot!.contents()!.count))
                expect(regeneratedDictionary!.root.digest).to(equal(regenerativeDictionary.root.digest))
            }
            describe("2D RGDictionaries or nested RGDictionaries") {
                typealias NestedDictionaryNodeType = RGDictionary256<UInt256, DictionaryStemType>
                let nestedDictionaryNode = NestedDictionaryNodeType([UInt256(0): dictionaryRoot!])
                it("node nested create") {
                    expect(nestedDictionaryNode).toNot(beNil())
                    expect(nestedDictionaryNode!.isComplete()).to(beTrue())
                }
                typealias NestedDictionaryStemType = RGCID<NestedDictionaryNodeType>
                let nestedDictionaryRoot = NestedDictionaryStemType(artifact: nestedDictionaryNode!, complete: true)
                it("root nested create") {
                    expect(nestedDictionaryRoot).toNot(beNil())
                }
                typealias RegenerativeNestedDictionaryType = RGObject256<NestedDictionaryStemType>
                let nestedRegenerative = RegenerativeNestedDictionaryType(root: nestedDictionaryRoot!)
                it("should have all node contents") {
                    expect(nestedRegenerative.complete()).to(beTrue())
                    expect(nestedRegenerative.contents()).toNot(beNil())
                    expect(nestedRegenerative.contents()!).toNot(beEmpty())
                }
                let cutNestedRegenerative = nestedRegenerative.cuttingAllNodes()
                let regeneratedNestedDictionary = cutNestedRegenerative.capture(info: nestedRegenerative.contents()!)
                it("can be regenerated fully and completely, bit for bit") {
                    expect(regeneratedNestedDictionary).toNot(beNil())
                    expect(regeneratedNestedDictionary!.complete()).to(beTrue())
                }
            }
        }
    }
}

