import Foundation
import Nimble
import Quick
import CryptoStarterPack
@testable import Regenerate

final class RGRTSpec: QuickSpec {
    override func spec() {
        describe("Regenerative Radix Merkle Trie") {
            describe("Initialization") {
                let rgrmt = RGRT256<UInt256, UInt256>()
                let oneKey = UInt256.min
                let anotherKey = UInt256.max
                let oneValue = UInt256.max
                let anotherValue = UInt256.min
                it("should initialize empty rrm") {
                    expect(rgrmt).toNot(beNil())
                }
                describe("setting, getting and deleting") {
                    let modifiedRRM = rgrmt.setting(key: oneKey, to: oneValue)
                    it("should set") {
                        expect(modifiedRRM).toNot(beNil())
                    }
                    it("should get the same value back") {
                        let resultOfGet = modifiedRRM!.get(key: oneKey)
                        expect(resultOfGet).toNot(beNil())
                        expect(resultOfGet!).to(equal(oneValue))
                    }
                    let deletedRRM = modifiedRRM!.deleting(key: oneKey)
                    it("should delete") {
                        expect(deletedRRM).toNot(beNil())
                    }
                    it("should know key") {
                        expect(deletedRRM!.knows(key: oneKey)).to(beTrue())
                    }
                    it("should not have value for key") {
                        expect(deletedRRM!.get(key: oneKey)).to(beNil())
                    }
                }
                describe("digest equivalency") {
                    it("should have unique keys") {
                        expect(oneKey).toNot(equal(anotherKey))
                    }
                    let oneRRM = rgrmt.setting(key: oneKey, to: oneValue)!.setting(key: anotherKey, to: anotherValue)!
                    let anotherRRM = rgrmt.setting(key: anotherKey, to: anotherValue)!.setting(key: oneKey, to: oneValue)!
                    it("should have the same digest for both rrm, since contents are the same") {
                        expect(oneRRM.digest).to(equal(anotherRRM.digest))
                    }
                }
                describe("transition proofs") {
                    let someRRM = rgrmt.setting(key: oneKey, to: oneValue)!.setting(key: anotherKey, to: anotherValue)!
                    let transitionRRM = someRRM.transitionProof(proofType: .deletion, for: oneKey)
                    it("because key exists, it should create transition proof of deletion") {
                        expect(transitionRRM).toNot(beNil())
                    }
                    let fullModifiedRRM = someRRM.deleting(key: oneKey)
                    let partialModifiedRRM = transitionRRM!.deleting(key: oneKey)
                    it("should successfully modify partial rrm as it has all required info") {
                        expect(partialModifiedRRM).toNot(beNil())
                    }
                    it("should have the same digest for both rrm's") {
                        expect(fullModifiedRRM!.digest).to(equal(partialModifiedRRM!.digest))
                    }
                    describe("merging proofs") {
                        let differentKey = UInt256(5)
                        let differentValue = UInt256(5)
                        it("should be different from other keys") {
                            expect(differentKey).toNot(equal(oneKey))
                            expect(differentKey).toNot(equal(anotherKey))
                        }
                        let deletionRRM = someRRM.transitionProof(proofType: .deletion, for: oneKey)!
                        let creationRRM = someRRM.transitionProof(proofType: .creation, for: differentKey)
                        it("because key does not exist, it should create transition proof of creation") {
                            expect(creationRRM).toNot(beNil())
                        }
                        let mergedRRM = deletionRRM.merging(creationRRM!)
                        let fullModifiedRRM = someRRM.deleting(key: oneKey)!.setting(key: differentKey, to: differentValue)!
                        let partialModifiedRRM = mergedRRM.deleting(key: oneKey)!.setting(key: differentKey, to: differentValue)
                        it("should successfully modify merged partial rrm as it has all required info") {
                            expect(partialModifiedRRM).toNot(beNil())
                        }
                        it("should have the same digest for both rrm's") {
                            expect(fullModifiedRRM.digest).to(equal(partialModifiedRRM!.digest))
                        }
                    }
                }
                describe("Regeneration") {
                    let someRRM = rgrmt.setting(key: oneKey, to: oneValue)!.setting(key: anotherKey, to: anotherValue)!
                    it("is complete") {
                        expect(someRRM.complete()).to(beTrue())
                    }
                    let rrmContents = someRRM.contents()
                    it("can extract node contents from complete") {
                        expect(rrmContents).toNot(beNil())
                        expect(rrmContents!).toNot(beEmpty())
                    }
                    describe("rrm with just root") {
                        let cutRRM = someRRM.cuttingAllNodes()
                        it("should have same digest as original") {
                            expect(cutRRM.digest).to(equal(someRRM.digest))
                        }
                        it("should have no contents") {
                            expect(cutRRM.contents()!).to(beEmpty())
                        }
                        describe("inserting back contents") {
                            let resultAfterInserting = cutRRM.capture(info: rrmContents!)
                            let otherResult = cutRRM.capture(info: rrmContents!.map { $0.value })
                            let finalResult = RGRT256<UInt256, UInt256>(root: cutRRM.root, data: rrmContents!.map { $0.value })
                            let initResult = RGRT256<UInt256, UInt256>(root: cutRRM.root, data: someRRM.pieces()!)
                            it("should be complete") {
                                expect(resultAfterInserting).toNot(beNil())
                                expect(resultAfterInserting!.0.complete()).to(beTrue())
                                expect(resultAfterInserting!.0.computedValidity()).to(beTrue())
                                expect(otherResult).toNot(beNil())
                                expect(otherResult!.0.complete()).to(beTrue())
                                expect(otherResult!.0.computedValidity()).to(beTrue())
                                expect(finalResult).toNot(beNil())
                                expect(finalResult!.complete()).to(beTrue())
                                expect(finalResult!.computedValidity()).to(beTrue())
                                expect(initResult).toNot(beNil())
                                expect(initResult!.complete()).to(beTrue())
                                expect(initResult!.computedValidity()).to(beTrue())
                            }
                            it("should output correct keys") {
                                expect(Set(resultAfterInserting!.1.map { $0.0 })).to(equal(Set([oneKey, anotherKey])))
                                expect(Set(otherResult!.1.map { $0.0 })).to(equal(Set([oneKey, anotherKey])))
                                
                            }
                            it("should output correct values") {
                                expect(Set(resultAfterInserting!.1.map { $0.1 })).to(equal(Set([oneValue, anotherValue])))
                                expect(Set(otherResult!.1.map { $0.1 })).to(equal(Set([oneValue, anotherValue])))
                            }
                        }
                    }
                    describe("malicious insertion") {
                        let cutRRM = someRRM.cuttingAllNodes()
                        let childNode = someRRM.root.artifact!.children.first!.value.artifact!
                        let childNodeContent = childNode.serialize()!
                        let rootDigest = someRRM.root.digest
                        it("should be the wrong digest") {
                            expect(childNode.hash()).toNot(beNil())
                            expect(rootDigest).toNot(beNil())
                            expect(childNode.hash()!).toNot(equal(rootDigest!))
                        }
                        let insertedResult = cutRRM.capture(content: childNodeContent, digest: rootDigest!)
                        it("should accept insertion") {
                            expect(insertedResult).toNot(beNil())
                        }
                        let otherResult = cutRRM.capture(content: childNodeContent)
                        it("should reject insertion") {
                            expect(otherResult).to(beNil())
                        }
                    }
                }
            }
        }
    }
}
