import AwesomeDictionary
import AwesomeTrie
import Bedrock
import CryptoStarterPack
import Foundation
import Nimble
import Quick
@testable import Regenerate

final class RGGenericSpec: QuickSpec {
    override func spec() {
        describe("Generic Data Structure") {
            struct Foo: RGArtifact {
                static let metafield1 = "array1"
                static let metafield2 = "array2"
                public let array1: ArrayStemType!
                public let array2: ArrayStemType!

                init(array1: ArrayStemType, array2: ArrayStemType) {
                    self.array1 = array1
                    self.array2 = array2
                }

                init?(artifact1: ArrayStemType.Artifact?, artifact2: ArrayStemType.Artifact?) {
                    guard let unwrappedArtifact1 = artifact1 else { return nil }
                    guard let unwrappedArtifact2 = artifact2 else { return nil }
                    guard let address1 = ArrayStemType(artifact: unwrappedArtifact1, complete: true) else { return nil }
                    guard let address2 = ArrayStemType(artifact: unwrappedArtifact2, complete: true) else { return nil }
                    self.array1 = address1
                    self.array2 = address2
                }

                func set(property: String, to child: CryptoBindable) -> Foo? {
                    guard let stemChild = child as? ArrayStemType else { return nil }
                    switch property {
                    case Self.metafield1:
                        return Self(array1: stemChild, array2: array2)
                    case Self.metafield2:
                        return Self(array1: array1, array2: stemChild)
                    default:
                        return nil
                    }
                }

                func get(property: String) -> CryptoBindable? {
                    switch property {
                    case Self.metafield1:
                        return array1
                    case Self.metafield2:
                        return array2
                    default:
                        return nil
                    }
                }

                static func properties() -> [String] {
                    return [Self.metafield1, Self.metafield2]
                }
            }

            // Data types
            typealias ChildNodeType = Scalar<UInt256>
            typealias ArrayNodeType = Array256<Address<ChildNodeType>>
            typealias ArrayStemType = Address<ArrayNodeType>
            typealias FooStemType = Address<Foo>
            typealias RegenerativeFooType = RGObject<FooStemType>

            // Initialize Data Structure
            let fooNode: Foo = Foo(
                artifact1: ArrayNodeType(artifacts: [ChildNodeType(scalar: UInt256.min),
                                                     ChildNodeType(scalar: UInt256.max)]),
                artifact2: ArrayNodeType(artifacts: [ChildNodeType(scalar: UInt256(109_303_931)),
                                                     ChildNodeType(scalar: UInt256(10922))])
            )!

            let regenerativeFoo = RegenerativeFooType(artifact: fooNode)

            let rootKey = RegenerativeFooType.Root.SymmetricKey.random()
            let rootKeyData = rootKey.toData()
            let rootKeyHash = RegenerativeFooType.Root.CryptoDelegateType.hash(rootKeyData)!

            let firstKey = RegenerativeFooType.Root.SymmetricKey.random()
            let firstKeyData = firstKey.toData()
            let firstKeyHash = RegenerativeFooType.Root.CryptoDelegateType.hash(firstKeyData)!

            let secondKey = RegenerativeFooType.Root.SymmetricKey.random()
            let secondKeyData = secondKey.toData()
            let secondKeyHash = RegenerativeFooType.Root.CryptoDelegateType.hash(secondKeyData)!

            let keys = CoveredTrie<String, Data>(trie: TrieMapping<String, Data>()
                .setting(keys: [Foo.metafield1, ArrayStemType.Digest(0).toString()], value: firstKeyData)
                .setting(keys: [Foo.metafield1, ArrayStemType.Digest(1).toString()], value: secondKeyData), cover: rootKeyData)

            let rootIV = RegenerativeFooType.Root.SymmetricIV.random()
            let encryptedFoo = regenerativeFoo!.encrypt(allKeys: keys, commonIv: rootIV.toData())!

            let allKeys = Mapping<Data, Data>()
                .setting(key: rootKeyHash, value: rootKeyData)
                .setting(key: firstKeyHash, value: firstKeyData)
                .setting(key: secondKeyHash, value: secondKeyData)

            let targets: TrieSet<String> = TrieSet<String>()
                .adding([Foo.metafield1, ArrayStemType.Digest(0).toString()])
                .adding([Foo.metafield1, ArrayStemType.Digest(1).toString()])

            let contents = encryptedFoo.contents(previousKey: rootKey.toData(), keys: allKeys).elements()

            let cutFoo: RegenerativeFooType = encryptedFoo.cuttingAllNodes().targeting(targets).0
            let regeneratedFoo: RegenerativeFooType? = cutFoo.capture(info: Dictionary(uniqueKeysWithValues: contents), keys: allKeys)
            it("should regenerate partially") {
                expect(regeneratedFoo!.root.artifact!.array1.artifact!.children.elements().count).to(equal(2))
                expect(regeneratedFoo!.root.artifact!.array1.artifact!.children.values().contains(where: { !$0.complete })).to(beFalse())
                expect(regeneratedFoo!.root.artifact!.array2.artifact).to(beNil())
            }
        }
    }
}
