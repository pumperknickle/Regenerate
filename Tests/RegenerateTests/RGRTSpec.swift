import Foundation
import Nimble
import Quick
import CryptoStarterPack
import Bedrock
import AwesomeTrie
@testable import Regenerate

final class RGRTSpec: QuickSpec {
    override func spec() {
        describe("Regenerative Radix Merkle Trie") {
			describe("targeting") {
				let tree = RT256<UInt256, UInt256>()
				
				// Values to populate
                let oneKey = UInt256.min
                let anotherKey = UInt256.max
                let oneValue = UInt256.max
                let anotherValue = UInt256.min
				let thirdKey = UInt256.max - UInt256(100000)
				let thirdValue = UInt256.max - UInt256(10000000)
				
				let modifiedRRM = tree.setting(key: oneKey, to: oneValue)!.setting(key: anotherKey, to: anotherValue)!.setting(key: thirdKey, to: thirdValue)!
				let contents = modifiedRRM.contents(previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
				let cutRRM = modifiedRRM.cuttingAllNodes()
				let emptyTargeted = cutRRM.targeting(keys: [oneKey])
				let result = emptyTargeted.0.capture(info: Dictionary(uniqueKeysWithValues: contents.elements()), previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
				it("result should just have one key") {
					expect(result!.0.get(key: oneKey)).toNot(beNil())
					expect(result!.0.keys()).toNot(beNil())
					expect(result!.0.keys()!.count).to(equal(1))
				}
			}
			describe("masking") {
				let tree = RT256<String, UInt256>()
				
				// Values to populate
				let firstKey = "hello world"
				let secondKey = "hello world1"
				let thirdKey = "other thing"
				
				let oneValue = UInt256.max
				let anotherValue = UInt256.min
				let thirdValue = UInt256.max - UInt256(10000000)
				
				let modifiedRRM = tree.setting(key: firstKey, to: oneValue)!.setting(key: secondKey, to: anotherValue)!.setting(key: thirdKey, to: thirdValue)!
				let contents = modifiedRRM.contents(previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
				let cutRRM = modifiedRRM.cuttingAllNodes()
				let emptyTargeted = cutRRM.masking(keys: [firstKey])
				let result = emptyTargeted.0.capture(info: Dictionary(uniqueKeysWithValues: contents.elements()), previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
				it("result should have two keys") {
					expect(result!.0.get(key: firstKey)).toNot(beNil())
					expect(result!.0.get(key: secondKey)).toNot(beNil())
					expect(result!.0.keys()).toNot(beNil())
					expect(result!.0.keys()!.count).to(equal(2))
				}
			}
            describe("Initialization") {
                
                // User defined data structure
                let rgrmt = RT256<UInt256, UInt256>()
                
                // Values to populate
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
                    // These two data structures should be equivalent down to the last bit
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
                    // Create full data structure
                    let someRRM = rgrmt.setting(key: oneKey, to: oneValue)!.setting(key: anotherKey, to: anotherValue)!
                    it("is complete") {
                        expect(someRRM.complete()).to(beTrue())
                    }
                    // blocks can be extracted
                    let rrmContents = someRRM.contents(previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
                    it("can extract node contents from complete") {
                        expect(rrmContents).toNot(beNil())
                        expect(rrmContents.elements()).toNot(beEmpty())
                    }
                    describe("rrm with just root") {
                        // Start with only the cryptographic link
						let cutRRM = someRRM.cuttingAllNodes().mask().0
                        it("should have same digest as original") {
							expect(cutRRM.digest).to(equal(someRRM.digest))
                        }
                        it("should have no contents") {
                            expect(cutRRM.contents(previousKey: nil, keys: TrieMapping<Bool, [Bool]>()).elements()).to(beEmpty())
                        }
                        describe("inserting back contents") {
                            let resultAfterInserting = cutRRM.capture(info: Dictionary(uniqueKeysWithValues: rrmContents.elements()), previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
                            let otherResult = cutRRM.capture(info: rrmContents.elements().map { $0.1 }, previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
                            it("should be complete") {
                                expect(resultAfterInserting).toNot(beNil())
                                expect(resultAfterInserting!.0.complete()).to(beTrue())
                                expect(resultAfterInserting!.0.computedValidity()).to(beTrue())
                                expect(otherResult).toNot(beNil())
                                expect(otherResult!.0.complete()).to(beTrue())
                                expect(otherResult!.0.computedValidity()).to(beTrue())
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
						let cutRRM = someRRM.cuttingAllNodes().mask().0
                        let childNode = someRRM.root.artifact!.children.elements().first!.1.artifact!
                        let childNodeContent = childNode.toBoolArray()
                        let rootDigest = someRRM.root.digest
                        let childNodeHash = BaseCrypto.hash(childNode.toBoolArray())
                        it("should be the wrong digest") {
                            expect(childNode.toBoolArray()).toNot(beNil())
                            expect(rootDigest).toNot(beNil())
                            expect(childNodeHash).toNot(beNil())
                            expect(Radix256.Digest(raw: childNodeHash!)).toNot(beNil())
                            expect(Radix256.Digest(raw: childNodeHash!)).toNot(equal(rootDigest!))
                        }
						let insertedResult = cutRRM.capture(content: childNodeContent, digestString: rootDigest!.toString(), previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
                        it("should accept insertion") {
                            expect(insertedResult).toNot(beNil())
                        }
                        let otherResult = cutRRM.capture(content: childNodeContent, previousKey: nil, keys: TrieMapping<Bool, [Bool]>())
                        it("should reject insertion") {
                            expect(otherResult).to(beNil())
                        }
                    }
                }
            }
        }
    }
}
