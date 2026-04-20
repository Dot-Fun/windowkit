import XCTest
@testable import UpdateChecker

final class SemanticVersionTests: XCTestCase {
    func testBasicOrdering() {
        XCTAssertLessThan(SemanticVersion("0.2.4")!, SemanticVersion("0.2.5")!)
        XCTAssertLessThan(SemanticVersion("0.9.9")!, SemanticVersion("1.0.0")!)
        XCTAssertLessThan(SemanticVersion("0.2.9")!, SemanticVersion("0.2.10")!)
    }

    func testEquality() {
        XCTAssertEqual(SemanticVersion("0.2.5"), SemanticVersion("0.2.5"))
        XCTAssertEqual(SemanticVersion("v0.2.5"), SemanticVersion("0.2.5"))
    }

    func testVPrefixStripped() {
        XCTAssertEqual(SemanticVersion("v1.2.3")?.components, [1, 2, 3])
    }

    func testPrereleaseSuffixDropped() {
        XCTAssertEqual(SemanticVersion("1.0.0-beta.1")?.components, [1, 0, 0])
    }

    func testNonNumericReturnsNil() {
        XCTAssertNil(SemanticVersion("nightly"))
        XCTAssertNil(SemanticVersion(""))
    }

    func testShorterVersionIsLess() {
        // 1.0 < 1.0.1
        XCTAssertLessThan(SemanticVersion("1.0")!, SemanticVersion("1.0.1")!)
    }
}
