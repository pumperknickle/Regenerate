import Foundation

public protocol DictionaryOverlay: RGDictionary where CoreType: RTOverlay { }

extension DictionaryOverlay {
    func targeting(_ targets: [Key]) -> Self? {
        guard let newCore = core.targeting(targets) else { return nil }
        return changing(core: newCore)
    }
    
    func masking(_ masks: [Key]) -> Self? {
        guard let newCore = core.masking(masks) else { return nil }
        return changing(core: newCore)
    }
}
