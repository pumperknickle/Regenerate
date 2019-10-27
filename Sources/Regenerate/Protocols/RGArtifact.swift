import Foundation
import Bedrock
import AwesomeDictionary
import AwesomeTrie

public protocol RGArtifact: Codable, BinaryEncodable {
    typealias Edge = String
    typealias Path = [Edge]
	
	func pruning() -> Self
	
    func isComplete() -> Bool
	func capture(digestString: String, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<String, [Path]>)?
    func missing(prefix: Path) -> Mapping<String, [Path]>
    func contents() -> Mapping<String, [Bool]>
	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>)
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>)
	func mask(prefix: [Edge]) -> (Self, Mapping<String, [Path]>)
	func shouldMask(_ masks: TrieSet<Edge>, prefix: [Edge]) -> Bool
	func set(key: [Bool]) -> Self?
	
	func set(property: String, to child: CryptoBindable) -> Self?
	func get(property: String) -> CryptoBindable?
	func properties() -> [String]
}

public extension RGArtifact {
	func capture(digestString: String, content: [Bool], at route: Path, prefix: Path) -> (Self, Mapping<String, [Path]>)? {
		guard let firstLeg = route.first else { return nil }
		guard let child = get(property: firstLeg) else { return nil }
		guard let result = child.capture(digestString: digestString, content: content, at: Array(route.dropFirst()), prefix: prefix + [firstLeg]) else { return nil }
		guard let finalSelf = set(property: firstLeg, to: result.0) else { return nil }
		return (finalSelf, result.1)
	}
	
	func set(key: [Bool]) -> Self? {
		return properties().reduce(self) { (result, entry) -> Self? in
			guard let result = result else { return nil }
			guard let child = result.get(property: entry) else { return nil }
			guard let childResult = child.set(key: key, iv: entry.toBoolArray()) else { return nil }
			return result.set(property: entry, to: childResult)
		}
	}
	
	func mask(prefix: [Edge]) -> (Self, Mapping<String, [Path]>) {
		return properties().reduce((self, Mapping<String, [Path]>())) { (result, entry) -> (Self, Mapping<String, [Path]>) in
			guard let value = get(property: entry) else { return result }
			let masked = value.mask(prefix: prefix + [entry])
			guard let afterMasking = set(property: entry, to: masked.0) else { return result }
			return (afterMasking, masked.1)
		}
	}
	
	func masking(_ masks: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) {
		return masks.children.keys().reduce((self, Mapping<String, [Path]>())) { (result, entry) -> (Self, Mapping<String, [Path]>) in
			guard let value = get(property: entry) else { return result }
			let masked = value.masking(masks.subtree(keys: [entry]), prefix: prefix + [entry])
			let finalMasks = masks.contains([entry]) ? masked.0.mask(prefix: prefix + [entry]) : (masked.0, Mapping<String, [Path]>())
			guard let afterMasking = set(property: entry, to: finalMasks.0) else { return result }
			return (afterMasking, masked.1 + finalMasks.1)
		}
	}

	func targeting(_ targets: TrieSet<Edge>, prefix: [Edge]) -> (Self, Mapping<String, [Path]>) {
		return targets.children.keys().reduce((self, Mapping<String, [Path]>())) { (result, entry) -> (Self, Mapping<String, [Path]>) in
			guard let value = get(property: entry) else { return result }
			let targeted = value.targeting(targets.subtree(keys: [entry]), prefix: prefix + [entry])
			let finalTargets = targets.contains([entry]) ? targeted.0.target(prefix: prefix + [entry]) : (targeted.0, Mapping<String, [Path]>())
			guard let afterSetting = set(property: entry, to: finalTargets.0) else { return result }
			return (afterSetting, targeted.1 + finalTargets.1)
		}
	}
	
	func contents() -> Mapping<String, [Bool]> {
		return properties().reduce(Mapping<String, [Bool]>()) { (result, entry) -> Mapping<String, [Bool]> in
			guard let value = get(property: entry) else { return result }
			return result.overwrite(with: value.contents())
		}
	}
	
	func missing(prefix: Path) -> Mapping<String, [Path]> {
		return properties().reduce(Mapping<String, [Path]>()) { (result, entry) -> Mapping<String, [Path]> in
			guard let value = get(property: entry) else { return result }
			return result + value.missing(prefix: prefix + [entry])
		}
	}
	
	func isComplete() -> Bool {
		return !properties().contains(where: {
			guard let value = get(property: $0) else { return true }
			return !value.isComplete()
		})
	}
	
	func pruning() -> Self {
		return properties().reduce(self) { (result, entry) -> Self in
			guard let value = get(property: entry) else { return self }
			guard let toReturn = set(property: entry, to: value.empty()) else { return self }
			return toReturn
		}
	}
	
    init?(raw: [Bool]) {
        guard let data = Data(raw: raw) else { return nil }
        guard let node = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        self = node
    }
    
    func toBoolArray() -> [Bool] {
        return try! JSONEncoder().encode(pruning()).toBoolArray()
    }
	
	func shouldMask(_ masks: TrieSet<Edge>, prefix: [Edge]) -> Bool {
		return false
	}
}
