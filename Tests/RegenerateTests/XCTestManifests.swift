#if !canImport(ObjectiveC)
    import XCTest

    public func __allTests() -> [XCTestCaseEntry] {
        return [
            testCase(RGArraySpec.allTests),
            testCase(RGDictionarySpec.allTests),
            testCase(RGGenericSpec.allTests),
            testCase(RGRTSpec.allTests),
        ]
    }
#endif
