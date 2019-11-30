import Foundation
import Nimble
import Quick
import CryptoStarterPack
import Bedrock
import AwesomeTrie
import AwesomeDictionary
@testable import Regenerate

final class RGGenericSpec: QuickSpec {
	override func spec() {
		describe("Generic Data Structure") {
			struct Foo: RGArtifact {
				let metafield1 = "array1"
				let metafield2 = "array2"
				public let array1: ArrayStemType!
				public let array2: ArrayStemType!
				
				init(array1: ArrayStemType, array2: ArrayStemType) {
					self.array1 = array1
					self.array2 = array2
				}
				
				func set(property: String, to child: CryptoBindable) -> Foo? {
					guard let stemChild = child as? ArrayStemType else { return nil }
					switch property {
					case metafield1:
						return Self(array1: stemChild, array2: array2)
					case metafield2:
						return Self(array1: array1, array2: stemChild)
					default:
						return nil
					}
				}
				
				func get(property: String) -> CryptoBindable? {
					switch property {
					case metafield1:
						return array1
					case metafield2:
						return array2
					default:
						return nil
					}
				}
				
				func properties() -> [String] {
					return [metafield1, metafield2]
				}
			}
			typealias ChildNodeType = Scalar<UInt256>
			typealias ChildStemType = Address<ChildNodeType>
			typealias ArrayNodeType = Array256<ChildStemType>
			typealias ArrayStemType = Address<ArrayNodeType>
			typealias FooStemType = Address<Foo>
			typealias RegenerativeFooType = RGObject<FooStemType>
			
			// array 0-0
			let firstNode = ChildNodeType(scalar: UInt256.min)
			let secondNode = ChildNodeType(scalar: UInt256.max)
			let firstStem = ChildStemType(artifact: firstNode, symmetricKeyHash: nil, symmetricIV: nil, complete: true)
			let secondStem = ChildStemType(artifact: secondNode, symmetricKeyHash: nil, symmetricIV: nil, complete: true)
			let arrayNode1 = ArrayNodeType([firstStem!, secondStem!])!
			let arrayStem1 = ArrayStemType(artifact: arrayNode1, symmetricKeyHash: nil, symmetricIV: nil, complete: true)

			// array 0-1
			let thirdNode = ChildNodeType(scalar: UInt256(109303931))
			let fourthNode = ChildNodeType(scalar: UInt256(10922))
			let thirdStem = ChildStemType(artifact: thirdNode, symmetricKeyHash: nil, symmetricIV: nil, complete: true)
			let fourthStem = ChildStemType(artifact: fourthNode, symmetricKeyHash: nil, symmetricIV: nil, complete: true)
			let arrayNode2 = ArrayNodeType([thirdStem!, fourthStem!])!
			let arrayStem2 = ArrayStemType(artifact: arrayNode2, symmetricKeyHash: nil, symmetricIV: nil, complete: true)
            
            let rootKey = RegenerativeFooType.Root.SymmetricKey.random()
            let rootKeyBinary = rootKey.toBoolArray()
            let rootKeyHash = RegenerativeFooType.Root.CryptoDelegateType.hash(rootKeyBinary)!
            
            let firstKey = RegenerativeFooType.Root.SymmetricKey.random()
            let firstKeyBinary = firstKey.toBoolArray()
            let firstKeyHash = RegenerativeFooType.Root.CryptoDelegateType.hash(firstKeyBinary)!

            let secondKey = RegenerativeFooType.Root.SymmetricKey.random()
            let secondKeyBinary = secondKey.toBoolArray()
            let secondKeyHash = RegenerativeFooType.Root.CryptoDelegateType.hash(secondKeyBinary)!
			
			let fooNode = Foo(array1: arrayStem1!, array2: arrayStem2!)
            let fooStem = FooStemType(artifact: fooNode, symmetricKeyHash: nil, symmetricIV: nil, complete: true)
            
            let keys = CoveredTrie<String, [Bool]>(trie: TrieMapping<String, [Bool]>().setting(keys: [fooNode.metafield1, ArrayStemType.Digest(0).toString()], value: firstKeyBinary).setting(keys: [fooNode.metafield1, ArrayStemType.Digest(1).toString()], value: secondKeyBinary), cover: rootKeyBinary)
            
            let rootIV = RegenerativeFooType.Root.SymmetricIV.random()
            let regenerativeFoo = RegenerativeFooType(root: fooStem!).encrypt(allKeys: keys, commonIv: rootIV.toBoolArray())!
            let allKeys = TrieMapping<Bool, [Bool]>().setting(keys: rootKeyHash, value: rootKeyBinary).setting(keys: firstKeyHash, value: firstKeyBinary).setting(keys: secondKeyHash, value: secondKeyBinary)
            
			let targets = TrieSet<String>().adding([fooNode.metafield1, ArrayStemType.Digest(0).toString()]).adding([fooNode.metafield1, ArrayStemType.Digest(1).toString()])

			let cutFoo = regenerativeFoo.cuttingAllNodes().targeting(targets)
			let regeneratedFoo = cutFoo.0.capture(info: Dictionary(uniqueKeysWithValues: regenerativeFoo.contents(previousKey: nil, keys: allKeys).elements()), previousKey: nil, keys: allKeys)
			it("should regenerate partially") {
				expect(regeneratedFoo!.root.artifact!.array1.artifact).toNot(beNil())
				expect(regeneratedFoo!.root.artifact!.array2.artifact).to(beNil())
			}
		}
	}
}
