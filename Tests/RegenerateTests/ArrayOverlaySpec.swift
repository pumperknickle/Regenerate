import Foundation
import Nimble
import Quick
import CryptoStarterPack
import Bedrock
@testable import Regenerate

final class ArrayOverlaySpec: QuickSpec {
    override func spec() {
        describe("Arrays") {
            describe("targeting indices") {
                typealias ElementType = UInt256
                typealias ChildNodeType = RGScalar256<ElementType>
                typealias ChildCIDType = RGCID<ChildNodeType>
                typealias ArrayNodeType = RGArray256<ChildCIDType>
                typealias ArrayCIDType = RGCID<ArrayNodeType>
                typealias ArrayOverlayNodeType = ArrayOverlay256<ChildCIDType>
                typealias ArrayOverlayCIDType = RGCID<ArrayOverlayNodeType>
                typealias ArrayOverlayObjectType = RGObject256<ArrayOverlayCIDType>
                
                let firstElement: ElementType = UInt256.max
                let secondElement: ElementType = UInt256.min
                let source = [firstElement, secondElement].map { ChildCIDType(artifact: ChildNodeType(raw: $0), complete: true)! }
                let arrayNode = ArrayNodeType(source)
                let arrayRoot = ArrayCIDType(artifact: arrayNode!)
                
                it("root should exist have contents") {
                    expect(arrayRoot).toNot(beNil())
                    expect(arrayRoot!.contents()).toNot(beNil())
                    expect(arrayRoot!.contents()!.elements()).toNot(beEmpty())
                }
                let overlayRoot = ArrayOverlayNodeType.CoreRootType(digest: arrayNode!.core.digest)
                let emptyArrayOverlayNode = ArrayOverlayNodeType(root: overlayRoot, length: UInt256(2))
                let configuredArrayOverlayNode = emptyArrayOverlayNode.targeting([UInt256(0)])
                let emptyArrayOverlayCID = ArrayOverlayCIDType(artifact: configuredArrayOverlayNode!)
                let emptyArrayOverlayObject = ArrayOverlayObjectType(root: emptyArrayOverlayCID!)
                it("shouldn't have any information since it was created with just a digest") {
                    expect(emptyArrayOverlayObject.root.artifact).toNot(beNil())
                    expect(emptyArrayOverlayObject.root.contents()).toNot(beNil())
                    expect(emptyArrayOverlayObject.root.artifact!.contents()!.elements()).to(beEmpty())
                    
                }
                let regeneratedArrayOverlayObject = emptyArrayOverlayObject.capture(info: Dictionary(uniqueKeysWithValues: arrayRoot!.contents()!.elements()))
                it("should be regenerated, but contain only 1 element in the array") {
                    expect(regeneratedArrayOverlayObject).toNot(beNil())
                    expect(regeneratedArrayOverlayObject!.root.artifact).toNot(beNil())
                    expect(regeneratedArrayOverlayObject!.root.artifact!.mapping.count).to(equal(1))
                    expect(regeneratedArrayOverlayObject!.complete()).to(beFalse())
                    expect(regeneratedArrayOverlayObject!.missingDigests()).to(beEmpty())
                }
            }
        }
    }
}
