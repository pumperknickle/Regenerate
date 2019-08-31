import Foundation

public protocol ArrayOverlay: RGArray where CoreType: RTOverlay { }

extension ArrayOverlay {
    func targeting(_ targets: [Index]) -> Self? {
        guard let newCore = core.targeting(targets) else { return nil }
        return changing(core: newCore)
    }
}
