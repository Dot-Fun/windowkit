import XCTest
@testable import WindowEngine

/// Tests assume top-left origin screen coordinates (AX convention) unless
/// noted otherwise. Screen origin is (0,0) except where a multi-display
/// offset is explicitly used.
final class GeometryTests: XCTestCase {

    // Common test screens.
    let macbook = CGRect(x: 0, y: 0, width: 1440, height: 900)
    let fullHD  = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let fourK   = CGRect(x: 0, y: 0, width: 3840, height: 2160)

    // MARK: - Halves (1440x900)

    func testLeftHalf() {
        let r = Geometry.targetFrame(for: .leftHalf, screen: macbook, current: .zero)
        XCTAssertEqual(r, CGRect(x: 0, y: 0, width: 720, height: 900))
    }

    func testRightHalf() {
        let r = Geometry.targetFrame(for: .rightHalf, screen: macbook, current: .zero)
        XCTAssertEqual(r, CGRect(x: 720, y: 0, width: 720, height: 900))
    }

    func testTopHalf() {
        let r = Geometry.targetFrame(for: .topHalf, screen: macbook, current: .zero)
        XCTAssertEqual(r, CGRect(x: 0, y: 0, width: 1440, height: 450))
    }

    func testBottomHalf() {
        let r = Geometry.targetFrame(for: .bottomHalf, screen: macbook, current: .zero)
        XCTAssertEqual(r, CGRect(x: 0, y: 450, width: 1440, height: 450))
    }

    func testHalvesTileExactly() {
        let left = Geometry.targetFrame(for: .leftHalf, screen: macbook, current: .zero)!
        let right = Geometry.targetFrame(for: .rightHalf, screen: macbook, current: .zero)!
        XCTAssertEqual(left.maxX, right.minX, "halves must share an edge")
        XCTAssertEqual(left.width + right.width, macbook.width)

        let top = Geometry.targetFrame(for: .topHalf, screen: macbook, current: .zero)!
        let bot = Geometry.targetFrame(for: .bottomHalf, screen: macbook, current: .zero)!
        XCTAssertEqual(top.maxY, bot.minY)
        XCTAssertEqual(top.height + bot.height, macbook.height)
    }

    // MARK: - 2x2 quadrants (1440x900)

    func testQuadrants() {
        XCTAssertEqual(Geometry.targetFrame(for: .topLeft,     screen: macbook, current: .zero),
                       CGRect(x: 0,   y: 0,   width: 720, height: 450))
        XCTAssertEqual(Geometry.targetFrame(for: .topRight,    screen: macbook, current: .zero),
                       CGRect(x: 720, y: 0,   width: 720, height: 450))
        XCTAssertEqual(Geometry.targetFrame(for: .bottomLeft,  screen: macbook, current: .zero),
                       CGRect(x: 0,   y: 450, width: 720, height: 450))
        XCTAssertEqual(Geometry.targetFrame(for: .bottomRight, screen: macbook, current: .zero),
                       CGRect(x: 720, y: 450, width: 720, height: 450))
    }

    func testQuadrantsTileExactly() {
        let cells: [WindowAction] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        let frames = cells.map { Geometry.targetFrame(for: $0, screen: macbook, current: .zero)! }
        let areaSum = frames.reduce(0) { $0 + ($1.width * $1.height) }
        XCTAssertEqual(areaSum, macbook.width * macbook.height)
    }

    // MARK: - 3x3 grid (1920x1080)

    func testGrid3TopLeft() {
        let r = Geometry.targetFrame(for: .grid3TopLeft, screen: fullHD, current: .zero)
        XCTAssertEqual(r, CGRect(x: 0, y: 0, width: 640, height: 360))
    }

    func testGrid3MiddleCenter() {
        let r = Geometry.targetFrame(for: .grid3MiddleCenter, screen: fullHD, current: .zero)
        XCTAssertEqual(r, CGRect(x: 640, y: 360, width: 640, height: 360))
    }

    func testGrid3BottomRight() {
        let r = Geometry.targetFrame(for: .grid3BottomRight, screen: fullHD, current: .zero)
        XCTAssertEqual(r, CGRect(x: 1280, y: 720, width: 640, height: 360))
    }

    func testGrid3TilesExactlyOn1920x1080() {
        let cells: [WindowAction] = [
            .grid3TopLeft, .grid3TopCenter, .grid3TopRight,
            .grid3MiddleLeft, .grid3MiddleCenter, .grid3MiddleRight,
            .grid3BottomLeft, .grid3BottomCenter, .grid3BottomRight
        ]
        let frames = cells.map { Geometry.targetFrame(for: $0, screen: fullHD, current: .zero)! }
        // Area sum == screen area (no gaps, no overlaps since all cells are disjoint rects).
        let areaSum = frames.reduce(0) { $0 + ($1.width * $1.height) }
        XCTAssertEqual(areaSum, fullHD.width * fullHD.height)
        // Union bounding box == screen.
        let union = frames.reduce(frames[0]) { $0.union($1) }
        XCTAssertEqual(union, fullHD)
        // Disjoint: sum of pairwise intersections is zero.
        for i in 0..<frames.count {
            for j in (i+1)..<frames.count {
                XCTAssertTrue(frames[i].intersection(frames[j]).isEmpty || frames[i].intersection(frames[j]).width * frames[i].intersection(frames[j]).height == 0)
            }
        }
    }

    func testGrid3TilesExactlyOnAwkwardSize() {
        // 1000x1000 — 1000/3 is not an integer; rounding must still tile.
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let cells: [WindowAction] = [
            .grid3TopLeft, .grid3TopCenter, .grid3TopRight,
            .grid3MiddleLeft, .grid3MiddleCenter, .grid3MiddleRight,
            .grid3BottomLeft, .grid3BottomCenter, .grid3BottomRight
        ]
        let frames = cells.map { Geometry.targetFrame(for: $0, screen: screen, current: .zero)! }
        let union = frames.reduce(frames[0]) { $0.union($1) }
        XCTAssertEqual(union, screen, "grid cells must tile exactly even with non-integer thirds")
        // Vertical boundaries must line up perfectly across rows.
        XCTAssertEqual(frames[0].maxX, frames[1].minX)
        XCTAssertEqual(frames[1].maxX, frames[2].minX)
        XCTAssertEqual(frames[3].maxX, frames[4].minX)
        XCTAssertEqual(frames[6].maxX, frames[7].minX)
        // Horizontal boundaries line up across columns.
        XCTAssertEqual(frames[0].maxY, frames[3].minY)
        XCTAssertEqual(frames[3].maxY, frames[6].minY)
    }

    // MARK: - Thirds

    func testThirdsTile() {
        let first  = Geometry.targetFrame(for: .firstThird,  screen: fullHD, current: .zero)!
        let center = Geometry.targetFrame(for: .centerThird, screen: fullHD, current: .zero)!
        let last   = Geometry.targetFrame(for: .lastThird,   screen: fullHD, current: .zero)!
        XCTAssertEqual(first,  CGRect(x: 0,    y: 0, width: 640, height: 1080))
        XCTAssertEqual(center, CGRect(x: 640,  y: 0, width: 640, height: 1080))
        XCTAssertEqual(last,   CGRect(x: 1280, y: 0, width: 640, height: 1080))
        XCTAssertEqual(first.maxX, center.minX)
        XCTAssertEqual(center.maxX, last.minX)
        XCTAssertEqual(first.width + center.width + last.width, fullHD.width)
    }

    func testTwoThirds() {
        XCTAssertEqual(Geometry.targetFrame(for: .firstTwoThirds, screen: fullHD, current: .zero),
                       CGRect(x: 0, y: 0, width: 1280, height: 1080))
        XCTAssertEqual(Geometry.targetFrame(for: .lastTwoThirds, screen: fullHD, current: .zero),
                       CGRect(x: 640, y: 0, width: 1280, height: 1080))
    }

    // MARK: - Horizontal bands

    func testHorizontalBandsTileExactlyFullHD() {
        let top = Geometry.targetFrame(for: .topThird, screen: fullHD, current: .zero)!
        let bottomTwo = Geometry.targetFrame(for: .bottomTwoThirds, screen: fullHD, current: .zero)!
        let bottom = Geometry.targetFrame(for: .bottomThird, screen: fullHD, current: .zero)!
        let topTwo = Geometry.targetFrame(for: .topTwoThirds, screen: fullHD, current: .zero)!

        // Full width everywhere
        for r in [top, bottomTwo, bottom, topTwo] {
            XCTAssertEqual(r.origin.x, fullHD.minX)
            XCTAssertEqual(r.width, fullHD.width)
        }

        // Exact tiling: topThird ∪ bottomTwoThirds covers screen with no gap/overlap
        XCTAssertEqual(top.minY, fullHD.minY)
        XCTAssertEqual(top.maxY, bottomTwo.minY)
        XCTAssertEqual(bottomTwo.maxY, fullHD.maxY)
        XCTAssertEqual(top.height + bottomTwo.height, fullHD.height)

        // And topTwoThirds ∪ bottomThird also tiles
        XCTAssertEqual(topTwo.minY, fullHD.minY)
        XCTAssertEqual(topTwo.maxY, bottom.minY)
        XCTAssertEqual(bottom.maxY, fullHD.maxY)
        XCTAssertEqual(topTwo.height + bottom.height, fullHD.height)
    }

    func testHorizontalBandsTileExactlyOddSize() {
        let square = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let top = Geometry.targetFrame(for: .topThird, screen: square, current: .zero)!
        let bottomTwo = Geometry.targetFrame(for: .bottomTwoThirds, screen: square, current: .zero)!
        let bottom = Geometry.targetFrame(for: .bottomThird, screen: square, current: .zero)!
        let topTwo = Geometry.targetFrame(for: .topTwoThirds, screen: square, current: .zero)!

        // Exact tiling even when height/3 is non-integer
        XCTAssertEqual(top.maxY, bottomTwo.minY)
        XCTAssertEqual(top.height + bottomTwo.height, square.height)
        XCTAssertEqual(topTwo.maxY, bottom.minY)
        XCTAssertEqual(topTwo.height + bottom.height, square.height)

        // Bands anchored correctly
        XCTAssertEqual(top.minY, square.minY)
        XCTAssertEqual(bottom.maxY, square.maxY)
    }

    // MARK: - Sixths (2 rows x 3 cols)

    func testSixthsTileExactly() {
        let cells: [WindowAction] = [
            .topLeftSixth, .topCenterSixth, .topRightSixth,
            .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth
        ]
        let frames = cells.map { Geometry.targetFrame(for: $0, screen: fullHD, current: .zero)! }
        let union = frames.reduce(frames[0]) { $0.union($1) }
        XCTAssertEqual(union, fullHD)
        let areaSum = frames.reduce(0) { $0 + ($1.width * $1.height) }
        XCTAssertEqual(areaSum, fullHD.width * fullHD.height)
    }

    func testTopLeftSixth() {
        let r = Geometry.targetFrame(for: .topLeftSixth, screen: fullHD, current: .zero)
        XCTAssertEqual(r, CGRect(x: 0, y: 0, width: 640, height: 540))
    }

    func testBottomRightSixth() {
        let r = Geometry.targetFrame(for: .bottomRightSixth, screen: fullHD, current: .zero)
        XCTAssertEqual(r, CGRect(x: 1280, y: 540, width: 640, height: 540))
    }

    // MARK: - Sizing

    func testFullscreen() {
        let r = Geometry.targetFrame(for: .fullscreen, screen: macbook, current: .zero)
        XCTAssertEqual(r, macbook)
    }

    func testAlmostMaximizeIs90PercentCentered() {
        let r = Geometry.targetFrame(for: .almostMaximize, screen: macbook, current: .zero)!
        XCTAssertEqual(r.width, 1296)   // 1440 * 0.9
        XCTAssertEqual(r.height, 810)   // 900 * 0.9
        XCTAssertEqual(r.midX, macbook.midX, accuracy: 1)
        XCTAssertEqual(r.midY, macbook.midY, accuracy: 1)
    }

    func testCenterPreservesSizeAndRecenters() {
        let current = CGRect(x: 10, y: 20, width: 400, height: 300)
        let r = Geometry.targetFrame(for: .center, screen: macbook, current: current)!
        XCTAssertEqual(r.size, current.size)
        XCTAssertEqual(r.midX, macbook.midX, accuracy: 1)
        XCTAssertEqual(r.midY, macbook.midY, accuracy: 1)
    }

    func testCenterClampsOversizedWindow() {
        let huge = CGRect(x: 0, y: 0, width: 9999, height: 9999)
        let r = Geometry.targetFrame(for: .center, screen: macbook, current: huge)!
        XCTAssertEqual(r.width, macbook.width)
        XCTAssertEqual(r.height, macbook.height)
    }

    func testLargerSizeGrowsAndClampsToScreen() {
        // Already screen-sized → can't grow further, stays clamped.
        let r = Geometry.targetFrame(for: .largerSize, screen: macbook, current: macbook)!
        XCTAssertEqual(r.width, macbook.width)
        XCTAssertEqual(r.height, macbook.height)
    }

    func testLargerSizeGrowsSmallWindow() {
        let small = CGRect(x: 100, y: 100, width: 400, height: 300)
        let r = Geometry.targetFrame(for: .largerSize, screen: macbook, current: small)!
        // +5% of 1440 = 72 width, +5% of 900 = 45 height
        XCTAssertEqual(r.width,  472)
        XCTAssertEqual(r.height, 345)
        // Center preserved.
        XCTAssertEqual(r.midX, small.midX, accuracy: 1)
        XCTAssertEqual(r.midY, small.midY, accuracy: 1)
    }

    func testSmallerSizeShrinksAndClampsToMinimum() {
        let tiny = CGRect(x: 100, y: 100, width: 110, height: 110)
        let r = Geometry.targetFrame(for: .smallerSize, screen: macbook, current: tiny)!
        XCTAssertGreaterThanOrEqual(r.width, Geometry.minimumWindowEdge)
        XCTAssertGreaterThanOrEqual(r.height, Geometry.minimumWindowEdge)
    }

    // MARK: - Non-geometric actions return nil

    func testNonGeometricActionsReturnNil() {
        for a in [WindowAction.nextDisplay, .previousDisplay, .undo, .redo] {
            XCTAssertNil(Geometry.targetFrame(for: a, screen: macbook, current: .zero),
                         "\(a) should be handled by the caller, not geometry")
        }
    }

    // MARK: - Multi-display (non-zero screen origin)

    func testHalvesOnOffsetScreen() {
        // Secondary display positioned at x=1440 in AX global coords.
        let secondary = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let left = Geometry.targetFrame(for: .leftHalf, screen: secondary, current: .zero)!
        XCTAssertEqual(left, CGRect(x: 1440, y: 0, width: 960, height: 1080))
        let right = Geometry.targetFrame(for: .rightHalf, screen: secondary, current: .zero)!
        XCTAssertEqual(right, CGRect(x: 2400, y: 0, width: 960, height: 1080))
    }

    func testGrid3OnOffsetScreen() {
        let screen = CGRect(x: -1920, y: -200, width: 1920, height: 1080)
        let tl = Geometry.targetFrame(for: .grid3TopLeft, screen: screen, current: .zero)!
        XCTAssertEqual(tl.origin, CGPoint(x: -1920, y: -200))
        let br = Geometry.targetFrame(for: .grid3BottomRight, screen: screen, current: .zero)!
        XCTAssertEqual(br.maxX, 0)
        XCTAssertEqual(br.maxY, 880)
    }

    // MARK: - 4K screen sanity

    func testGrid3TilesOn4K() {
        let cells: [WindowAction] = [
            .grid3TopLeft, .grid3TopCenter, .grid3TopRight,
            .grid3MiddleLeft, .grid3MiddleCenter, .grid3MiddleRight,
            .grid3BottomLeft, .grid3BottomCenter, .grid3BottomRight
        ]
        let frames = cells.map { Geometry.targetFrame(for: $0, screen: fourK, current: .zero)! }
        let union = frames.reduce(frames[0]) { $0.union($1) }
        XCTAssertEqual(union, fourK)
    }

    // MARK: - CoordinateConverter

    func testAXToCocoaRoundtrip() {
        let primaryHeight: CGFloat = 900
        let ax = CGRect(x: 100, y: 50, width: 400, height: 300)
        let cocoa = CoordinateConverter.axToCocoa(ax, primaryHeight: primaryHeight)
        // AX y=50 (top), height=300 → Cocoa y = 900 - 50 - 300 = 550 (bottom).
        XCTAssertEqual(cocoa, CGRect(x: 100, y: 550, width: 400, height: 300))
        let back = CoordinateConverter.cocoaToAX(cocoa, primaryHeight: primaryHeight)
        XCTAssertEqual(back, ax)
    }

    func testAXToCocoaAtOrigin() {
        // AX top-left at (0,0) → Cocoa bottom-left at (0, primaryHeight - height).
        let cocoa = CoordinateConverter.axToCocoa(
            CGRect(x: 0, y: 0, width: 200, height: 200),
            primaryHeight: 900
        )
        XCTAssertEqual(cocoa, CGRect(x: 0, y: 700, width: 200, height: 200))
    }

    // MARK: - Action coverage

    func testEveryGeometricActionProducesAFrame() {
        let nonGeometric: Set<WindowAction> = [.nextDisplay, .previousDisplay, .undo, .redo]
        for action in WindowAction.allCases where !nonGeometric.contains(action) {
            let result = Geometry.targetFrame(
                for: action,
                screen: macbook,
                current: CGRect(x: 100, y: 100, width: 400, height: 300)
            )
            XCTAssertNotNil(result, "\(action) should produce a frame")
        }
    }
}
