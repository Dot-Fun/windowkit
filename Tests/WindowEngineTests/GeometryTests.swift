import XCTest
@testable import WindowEngine

final class GeometryTests: XCTestCase {
    func testStubReturnsCurrentFrame() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let current = CGRect(x: 100, y: 100, width: 400, height: 300)
        XCTAssertEqual(Geometry.frame(for: .leftHalf, in: screen, current: current), current)
    }
}
