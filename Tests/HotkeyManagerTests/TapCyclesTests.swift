import XCTest
import CoreGraphics
import WindowEngine
@testable import HotkeyManager

final class TapCyclesTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)

    /// Target frame for a fixed-slice cycle step on the test screen. All cycle
    /// steps ignore `current`, so `.zero` is fine here.
    private func frame(of action: WindowAction) -> CGRect {
        Geometry.targetFrame(for: action, screen: screen, current: .zero)!
    }

    /// Standing exactly on each step of `cycle`, a press of `primary` advances
    /// to the next step and wraps after the last.
    private func assertAdvancesThroughCycle(
        _ primary: WindowAction,
        _ cycle: [WindowAction],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for (i, step) in cycle.enumerated() {
            let current = frame(of: step)
            let expected = cycle[(i + 1) % cycle.count]
            XCTAssertEqual(
                TapCycles.next(primary, current: current, screen: screen),
                expected,
                "standing on \(step) should advance to \(expected)",
                file: file, line: line
            )
        }
    }

    func testDirectionalCyclesAdvanceByGeometry() {
        assertAdvancesThroughCycle(.grid3MiddleLeft,   [.leftHalf, .firstThird, .firstTwoThirds, .grid3MiddleLeft])
        assertAdvancesThroughCycle(.grid3MiddleRight,  [.rightHalf, .lastThird, .lastTwoThirds, .grid3MiddleRight])
        assertAdvancesThroughCycle(.grid3TopCenter,    [.topHalf, .topThird, .topTwoThirds, .grid3TopCenter])
        assertAdvancesThroughCycle(.grid3BottomCenter, [.bottomHalf, .bottomThird, .bottomTwoThirds, .grid3BottomCenter])
    }

    func testCornerAndCenterCyclesAdvanceByGeometry() {
        assertAdvancesThroughCycle(.grid3TopLeft,      [.topLeft, .grid3TopLeft, .topLeftTwoThirds])
        assertAdvancesThroughCycle(.grid3MiddleCenter, [.fullscreen, .grid3MiddleCenter, .centerThird])
    }

    func testFirstPressFromNonCycleLayoutStartsAtFirstStep() {
        // A small floating window that matches no cycle step.
        let floating = CGRect(x: 500, y: 400, width: 300, height: 220)
        XCTAssertEqual(TapCycles.next(.grid3MiddleLeft,   current: floating, screen: screen), .leftHalf)
        XCTAssertEqual(TapCycles.next(.grid3MiddleRight,  current: floating, screen: screen), .rightHalf)
        XCTAssertEqual(TapCycles.next(.grid3MiddleCenter, current: floating, screen: screen), .fullscreen)
    }

    func testNearMissWithinToleranceStillAdvances() {
        // A window placed slightly off leftHalf (within the match threshold)
        // still counts as occupying that step, so a press advances to firstThird.
        var nudged = frame(of: .leftHalf)
        nudged.origin.x += 8
        nudged.size.height -= 6
        XCTAssertLessThanOrEqual(
            Geometry.frameDistance(nudged, frame(of: .leftHalf)),
            TapCycles.matchThreshold(for: screen)
        )
        XCTAssertEqual(TapCycles.next(.grid3MiddleLeft, current: nudged, screen: screen), .firstThird)
    }

    func testNonCycleActionReturnsSelf() {
        let any = CGRect(x: 10, y: 20, width: 300, height: 200)
        XCTAssertEqual(TapCycles.next(.leftHalf,   current: any, screen: screen), .leftHalf)
        XCTAssertEqual(TapCycles.next(.fullscreen, current: any, screen: screen), .fullscreen)
        XCTAssertEqual(TapCycles.next(.undo,       current: any, screen: screen), .undo)
    }
}
