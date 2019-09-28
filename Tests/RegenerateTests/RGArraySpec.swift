import Foundation
import Nimble
import Quick
import CryptoStarterPack
import Bedrock
@testable import Regenerate

final class RGArraySpec: QuickSpec {
    override func spec() {
        describe("Array Merkle Structure") {
            typealias ChildNodeType = RGScalar256<UInt256>
            typealias ChildStemType = RGCID<ChildNodeType>
            typealias ArrayNodeType = RGArray256<ChildStemType>
            typealias ArrayStemType = RGCID<ArrayNodeType>
            typealias RegenerativeArrayType = RGObject256<ArrayStemType>
            
            let firstNode = ChildNodeType(raw: UInt256.min)
            let secondNode = ChildNodeType(raw: UInt256.max)
            let firstStem = ChildStemType(artifact: firstNode, complete: true)
            let secondStem = ChildStemType(artifact: secondNode, complete: true)
            it("should create simple scalar stems") {
                expect(firstStem).toNot(beNil())
                expect(secondStem).toNot(beNil())
            }
            let arrayNode = ArrayNodeType([firstStem!, secondStem!])
            it("should create with raw array") {
                expect(arrayNode).toNot(beNil())
                expect(arrayNode!.length).to(equal(UInt256(2)))
            }
            it("should create same array when starting from empty and appending") {
                let emptyNode = ArrayNodeType([])
                expect(emptyNode).toNot(beNil())
                let finalNode = emptyNode!.appending(firstStem!)!.appending(secondStem!)
                expect(finalNode).toNot(beNil())
                expect(finalNode!.toBoolArray()).to(equal(arrayNode!.toBoolArray()))
            }
            let arrayRoot = ArrayStemType(artifact: arrayNode!)
            it("should have node content and not be nil") {
                expect(arrayRoot).toNot(beNil())
                expect(arrayRoot!.contents()).toNot(beNil())
                expect(arrayRoot!.contents()!.elements()).toNot(beEmpty())
            }
            let regenerativeArray = RegenerativeArrayType(root: arrayRoot!)
            it("can extract node information") {
                expect(regenerativeArray.contents()).toNot(beNil())
                expect(regenerativeArray.contents()!.elements()).toNot(beEmpty())
            }
            let cutRegenerativeArray = regenerativeArray.cuttingAllNodes()
            it("can have just digest") {
                expect(cutRegenerativeArray.root.digest).to(equal(regenerativeArray.root.digest))
                expect(cutRegenerativeArray.contents()).toNot(beNil())
                expect(cutRegenerativeArray.contents()!.elements()).to(beEmpty())
            }
            let regeneratedArray = cutRegenerativeArray.capture(info: Dictionary(uniqueKeysWithValues: regenerativeArray.contents()!.elements()))
            it("can regenerate") {
                expect(regeneratedArray).toNot(beNil())
                expect(regeneratedArray!.complete()).to(beTrue())
                expect(regeneratedArray!.contents()).toNot(beNil())
                expect(regeneratedArray!.contents()!.elements().count).to(equal(arrayRoot!.contents()!.elements().count))
                expect(regeneratedArray!.root.digest).to(equal(regenerativeArray.root.digest))
            }
            describe("2D RGArrays or nested RGArrays") {
                typealias NestedArrayNodeType = RGArray256<ArrayStemType>
                let nestedArrayNode = NestedArrayNodeType([arrayRoot!])
                it("node can be created in nested manner"){
                    expect(nestedArrayNode).toNot(beNil())
                    expect(nestedArrayNode!.isComplete()).to(beTrue())
                }
                typealias NestedArrayStemType = RGCID<NestedArrayNodeType>
                let nestedArrayRoot = NestedArrayStemType(artifact: nestedArrayNode!, complete: true)
                it("root be created in nested manner") {
                    expect(nestedArrayRoot).toNot(beNil())
                }
                typealias RegenerativeNestedArrayType = RGObject256<NestedArrayStemType>
                let nestedRegenerative = RegenerativeNestedArrayType(root: nestedArrayRoot!)
                it("should have all node contents") {
                    expect(nestedRegenerative.complete()).to(beTrue())
                    expect(nestedRegenerative.contents()).toNot(beNil())
                    expect(nestedRegenerative.contents()!.elements()).toNot(beEmpty())
                }
                let cutNestedRegenerative = nestedRegenerative.cuttingAllNodes()
                let regeneratedNestedArray = cutNestedRegenerative.capture(info: Dictionary(uniqueKeysWithValues: nestedRegenerative.contents()!.elements()))
                it("can be regenerated fully and completely, bit for bit") {
                    expect(regeneratedNestedArray).toNot(beNil())
                    expect(regeneratedNestedArray!.complete()).to(beTrue())
                    expect(regeneratedNestedArray!.root.digest).to(equal(nestedRegenerative.root.digest))
                    expect(regeneratedNestedArray!.root.artifact!.length).to(equal(UInt256(1)))
                    expect(regeneratedNestedArray!.root.artifact!.mapping.values().first!.artifact!.length).to(equal(UInt256(2)))
                }
            }
        }
    }
}
