import XCTest
@testable import WindowEngine

/// Verifies the numpad sequence language against every rule in the spec.
/// The numpad is a literal 3×3 map of the screen:
///
///     7 8 9
///     4 5 6
///     1 2 3
final class NumpadRegionResolverTests: XCTestCase {

    private func region(_ digits: [Int]) -> GridRegion? {
        NumpadRegionResolver.resolve(digits)
    }

    // MARK: single cells (1/9)

    func testSingleCells() {
        XCTAssertEqual(region([7]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 1, rowStart: 0, rowEnd: 1))
        XCTAssertEqual(region([8]), GridRegion(cols: 3, rows: 3, colStart: 1, colEnd: 2, rowStart: 0, rowEnd: 1))
        XCTAssertEqual(region([9]), GridRegion(cols: 3, rows: 3, colStart: 2, colEnd: 3, rowStart: 0, rowEnd: 1))
        XCTAssertEqual(region([4]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 1, rowStart: 1, rowEnd: 2))
        XCTAssertEqual(region([5]), GridRegion(cols: 3, rows: 3, colStart: 1, colEnd: 2, rowStart: 1, rowEnd: 2))
        XCTAssertEqual(region([6]), GridRegion(cols: 3, rows: 3, colStart: 2, colEnd: 3, rowStart: 1, rowEnd: 2))
        XCTAssertEqual(region([1]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 1, rowStart: 2, rowEnd: 3))
        XCTAssertEqual(region([2]), GridRegion(cols: 3, rows: 3, colStart: 1, colEnd: 2, rowStart: 2, rowEnd: 3))
        XCTAssertEqual(region([3]), GridRegion(cols: 3, rows: 3, colStart: 2, colEnd: 3, rowStart: 2, rowEnd: 3))
    }

    // MARK: two-cell dominoes (bounding box of adjacent cells)

    func testHorizontalDomino() {
        // 1-2 → bottom-left + bottom-center
        XCTAssertEqual(region([1, 2]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 2, rowStart: 2, rowEnd: 3))
    }

    func testVerticalDomino() {
        // 6-9 → top-right + middle-right
        XCTAssertEqual(region([6, 9]), GridRegion(cols: 3, rows: 3, colStart: 2, colEnd: 3, rowStart: 0, rowEnd: 2))
    }

    func testOrderIndependent() {
        XCTAssertEqual(region([2, 1]), region([1, 2]))
        XCTAssertEqual(region([9, 6]), region([6, 9]))
        XCTAssertEqual(region([5, 7]), region([7, 5]))
    }

    // MARK: 2×2 blocks (corner → center)

    func test2x2Blocks() {
        XCTAssertEqual(region([7, 5]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 2, rowStart: 0, rowEnd: 2)) // top-left
        XCTAssertEqual(region([9, 5]), GridRegion(cols: 3, rows: 3, colStart: 1, colEnd: 3, rowStart: 0, rowEnd: 2)) // top-right
        XCTAssertEqual(region([1, 5]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 2, rowStart: 1, rowEnd: 3)) // bottom-left
        XCTAssertEqual(region([3, 5]), GridRegion(cols: 3, rows: 3, colStart: 1, colEnd: 3, rowStart: 1, rowEnd: 3)) // bottom-right
    }

    // MARK: full rows = horizontal third bands

    func testRowThirds() {
        XCTAssertEqual(region([7, 9]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 0, rowEnd: 1)) // top
        XCTAssertEqual(region([4, 6]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 1, rowEnd: 2)) // middle
        XCTAssertEqual(region([1, 3]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 2, rowEnd: 3)) // bottom
        // 7-8-9 is the same band as 7-9
        XCTAssertEqual(region([7, 8, 9]), region([7, 9]))
    }

    // MARK: full columns = vertical thirds

    func testColumnThirds() {
        XCTAssertEqual(region([7, 1]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 1, rowStart: 0, rowEnd: 3)) // left
        XCTAssertEqual(region([8, 2]), GridRegion(cols: 3, rows: 3, colStart: 1, colEnd: 2, rowStart: 0, rowEnd: 3)) // center
        XCTAssertEqual(region([9, 3]), GridRegion(cols: 3, rows: 3, colStart: 2, colEnd: 3, rowStart: 0, rowEnd: 3)) // right
        // 1-4-7 is the same column as 7-1
        XCTAssertEqual(region([1, 4, 7]), region([7, 1]))
    }

    // MARK: two-thirds

    func testTwoThirds() {
        XCTAssertEqual(region([7, 6]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 0, rowEnd: 2)) // top 2/3
        XCTAssertEqual(region([4, 3]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 1, rowEnd: 3)) // bottom 2/3
        XCTAssertEqual(region([7, 2]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 2, rowStart: 0, rowEnd: 3)) // left 2/3
        XCTAssertEqual(region([8, 3]), GridRegion(cols: 3, rows: 3, colStart: 1, colEnd: 3, rowStart: 0, rowEnd: 3)) // right 2/3
    }

    // MARK: fullscreen via opposite corners

    func testFullscreenOppositeCorners() {
        let full = GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 0, rowEnd: 3)
        XCTAssertEqual(region([7, 3]), full)
        XCTAssertEqual(region([9, 1]), full)
        XCTAssertEqual(region([1, 9]), full)
    }

    // MARK: halves (edge-center doubled)

    func testHalves() {
        XCTAssertEqual(region([4, 4]), GridRegion(cols: 2, rows: 2, colStart: 0, colEnd: 1, rowStart: 0, rowEnd: 2)) // left
        XCTAssertEqual(region([6, 6]), GridRegion(cols: 2, rows: 2, colStart: 1, colEnd: 2, rowStart: 0, rowEnd: 2)) // right
        XCTAssertEqual(region([8, 8]), GridRegion(cols: 2, rows: 2, colStart: 0, colEnd: 2, rowStart: 0, rowEnd: 1)) // top
        XCTAssertEqual(region([2, 2]), GridRegion(cols: 2, rows: 2, colStart: 0, colEnd: 2, rowStart: 1, rowEnd: 2)) // bottom
    }

    // MARK: quadrants (corner doubled)

    func testQuadrants() {
        XCTAssertEqual(region([7, 7]), GridRegion(cols: 2, rows: 2, colStart: 0, colEnd: 1, rowStart: 0, rowEnd: 1)) // top-left
        XCTAssertEqual(region([9, 9]), GridRegion(cols: 2, rows: 2, colStart: 1, colEnd: 2, rowStart: 0, rowEnd: 1)) // top-right
        XCTAssertEqual(region([1, 1]), GridRegion(cols: 2, rows: 2, colStart: 0, colEnd: 1, rowStart: 1, rowEnd: 2)) // bottom-left
        XCTAssertEqual(region([3, 3]), GridRegion(cols: 2, rows: 2, colStart: 1, colEnd: 2, rowStart: 1, rowEnd: 2)) // bottom-right
    }

    // MARK: thirds via triple-tap (edge-center)

    func testTripleTapThirds() {
        XCTAssertEqual(region([4, 4, 4]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 1, rowStart: 0, rowEnd: 3)) // left third
        XCTAssertEqual(region([6, 6, 6]), GridRegion(cols: 3, rows: 3, colStart: 2, colEnd: 3, rowStart: 0, rowEnd: 3)) // right third
        XCTAssertEqual(region([8, 8, 8]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 0, rowEnd: 1)) // top third
        XCTAssertEqual(region([2, 2, 2]), GridRegion(cols: 3, rows: 3, colStart: 0, colEnd: 3, rowStart: 2, rowEnd: 3)) // bottom third
    }

    // MARK: center maximize

    func testCenterMaximize() {
        XCTAssertEqual(region([5, 5]), .fullscreen)
        XCTAssertEqual(region([5, 5, 5]), .fullscreen)
    }

    // MARK: invalid / edge

    func testInvalid() {
        XCTAssertNil(region([]))
        XCTAssertNil(region([0]))
        XCTAssertNil(region([0, 0]))
    }

    func testNonKeypadDigitsIgnored() {
        XCTAssertEqual(region([7, 0]), region([7]))       // 0 ignored → single cell
        XCTAssertEqual(region([7, 3, 0]), region([7, 3])) // 0 ignored → fullscreen
    }

    func testDistinctWithRepeatCollapsesToBoundingBox() {
        // Repeats within a distinct set still resolve to the bounding box.
        XCTAssertEqual(region([7, 3, 3]), region([7, 3]))
        XCTAssertEqual(region([7, 7, 5]), region([7, 5]))
    }

    // MARK: frame integration — exact tiling on a 900×600 screen

    func testFramesTileScreen() {
        let screen = CGRect(x: 0, y: 0, width: 900, height: 600)

        // single top-left ninth
        XCTAssertEqual(Geometry.frame(for: region([7])!, screen: screen),
                       CGRect(x: 0, y: 0, width: 300, height: 200))
        // left half
        XCTAssertEqual(Geometry.frame(for: region([4, 4])!, screen: screen),
                       CGRect(x: 0, y: 0, width: 450, height: 600))
        // top-left quadrant
        XCTAssertEqual(Geometry.frame(for: region([7, 7])!, screen: screen),
                       CGRect(x: 0, y: 0, width: 450, height: 300))
        // fullscreen via opposite corners
        XCTAssertEqual(Geometry.frame(for: region([7, 3])!, screen: screen), screen)
        // bottom-right ninth
        XCTAssertEqual(Geometry.frame(for: region([3])!, screen: screen),
                       CGRect(x: 600, y: 400, width: 300, height: 200))
    }

    /// The nine single-cell regions must cover the screen with no gaps/overlaps.
    func testNineCellsCoverScreenExactly() {
        let screen = CGRect(x: 0, y: 0, width: 900, height: 600)
        var area: CGFloat = 0
        for d in 1...9 {
            let f = Geometry.frame(for: region([d])!, screen: screen)
            area += f.width * f.height
        }
        XCTAssertEqual(area, screen.width * screen.height, accuracy: 0.5)
    }
}
