import XCTest

import RegenerateTests

var tests = [XCTestCaseEntry]()
tests += RegenerateTests.allTests()
XCTMain(tests)
