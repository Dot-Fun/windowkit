import XCTest
@testable import WindowEngine

/// Verifies the overlay's region labels + fraction math.
final class GridRegionDescribeTests: XCTestCase {

    private func name(_ digits: [Int]) -> String? {
        NumpadRegionResolver.resolve(digits)?.describe()
    }

    func testDescribeNames() {
        XCTAssertEqual(name([7, 3]), "Fullscreen")
        XCTAssertEqual(name([5, 5]), "Fullscreen")
        XCTAssertEqual(name([4, 4]), "Left Half")
        XCTAssertEqual(name([6, 6]), "Right Half")
        XCTAssertEqual(name([8, 8]), "Top Half")
        XCTAssertEqual(name([2, 2]), "Bottom Half")
        XCTAssertEqual(name([7, 7]), "Top-Left Quarter")
        XCTAssertEqual(name([3, 3]), "Bottom-Right Quarter")
        XCTAssertEqual(name([7, 1]), "Left Third")
        XCTAssertEqual(name([9, 3]), "Right Third")
        XCTAssertEqual(name([7, 9]), "Top Third")
        XCTAssertEqual(name([1, 3]), "Bottom Third")
        XCTAssertEqual(name([7, 5]), "Top-Left 2×2")
        XCTAssertEqual(name([3, 5]), "Bottom-Right 2×2")
        XCTAssertEqual(name([7, 6]), "Top Two-Thirds")
        XCTAssertEqual(name([7, 2]), "Left Two-Thirds")
        XCTAssertEqual(name([7]), "Top Left Cell")
        XCTAssertEqual(name([5]), "Middle Center Cell")
        XCTAssertEqual(name([3]), "Bottom Right Cell")
    }

    func testFractions() {
        let cell = NumpadRegionResolver.resolve([7])!.fractions
        XCTAssertEqual(cell.x, 0, accuracy: 0.001)
        XCTAssertEqual(cell.y, 0, accuracy: 0.001)
        XCTAssertEqual(cell.w, 1.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(cell.h, 1.0 / 3.0, accuracy: 0.001)

        let leftHalf = NumpadRegionResolver.resolve([4, 4])!.fractions
        XCTAssertEqual(leftHalf.x, 0, accuracy: 0.001)
        XCTAssertEqual(leftHalf.w, 0.5, accuracy: 0.001)
        XCTAssertEqual(leftHalf.h, 1, accuracy: 0.001)

        let full = GridRegion.fullscreen.fractions
        XCTAssertEqual(full.w, 1, accuracy: 0.001)
        XCTAssertEqual(full.h, 1, accuracy: 0.001)
    }
}
