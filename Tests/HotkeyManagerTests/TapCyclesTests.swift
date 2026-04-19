import XCTest
import WindowEngine
@testable import HotkeyManager

final class TapCyclesTests: XCTestCase {
    func testMiddleLeftFourStepCycle() {
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 1), .grid3MiddleLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 2), .firstThird)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 3), .leftHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 4), .firstTwoThirds)
    }

    func testWrapOnFifthTap() {
        // 4-step cycle wraps to step 1 at tap 5.
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 5), .grid3MiddleLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 6), .firstThird)
        // 2-step cycle wraps to step 1 at tap 3.
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 3), .grid3TopLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 4), .topLeft)
    }

    func testCornerCyclesTwoSteps() {
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 1), .grid3TopLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 2), .topLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3TopRight, tapCount: 2), .topRight)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomLeft, tapCount: 2), .bottomLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomRight, tapCount: 2), .bottomRight)
    }

    func testMiddleCenterTwoStepCycle() {
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleCenter, tapCount: 1), .grid3MiddleCenter)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleCenter, tapCount: 2), .fullscreen)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleCenter, tapCount: 3), .grid3MiddleCenter)
    }

    func testVerticalBandCycles() {
        XCTAssertEqual(TapCycles.resolve(.grid3TopCenter, tapCount: 2), .topThird)
        XCTAssertEqual(TapCycles.resolve(.grid3TopCenter, tapCount: 3), .topHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3TopCenter, tapCount: 4), .topTwoThirds)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomCenter, tapCount: 2), .bottomThird)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomCenter, tapCount: 3), .bottomHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomCenter, tapCount: 4), .bottomTwoThirds)
    }

    func testMiddleRightCycle() {
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleRight, tapCount: 2), .lastThird)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleRight, tapCount: 3), .rightHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleRight, tapCount: 4), .lastTwoThirds)
    }

    func testNonCycleActionReturnsSelf() {
        XCTAssertEqual(TapCycles.resolve(.leftHalf, tapCount: 1), .leftHalf)
        XCTAssertEqual(TapCycles.resolve(.leftHalf, tapCount: 5), .leftHalf)
        XCTAssertEqual(TapCycles.resolve(.fullscreen, tapCount: 2), .fullscreen)
        XCTAssertEqual(TapCycles.resolve(.undo, tapCount: 3), .undo)
    }

    func testAllNineGridActionsPresentWithStepOne() {
        let grid: [WindowAction] = [
            .grid3TopLeft, .grid3TopCenter, .grid3TopRight,
            .grid3MiddleLeft, .grid3MiddleCenter, .grid3MiddleRight,
            .grid3BottomLeft, .grid3BottomCenter, .grid3BottomRight,
        ]
        for action in grid {
            XCTAssertEqual(TapCycles.resolve(action, tapCount: 1), action)
        }
    }
}
