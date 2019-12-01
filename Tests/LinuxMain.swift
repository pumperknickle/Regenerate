import XCTest

import RegenerateTests

var tests = [XCTestCaseEntry]()
tests += RegenerateTests.__allTests()

XCTMain(tests)
