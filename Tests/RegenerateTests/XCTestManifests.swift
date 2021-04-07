#if !canImport(ObjectiveC)
    import XCTest

    public func __allTests() -> [XCTestCaseEntry] {
        return [
            testCase(RGArraySpec.__allTests__RGArraySpec),
            testCase(RGDictionarySpec.__allTests__RGDictionarySpec),
            testCase(RGGenericSpec.__allTests__RGGenericSpec),
            testCase(RGRTSpec.__allTests__RGRTSpec),
        ]
    }
#endif
