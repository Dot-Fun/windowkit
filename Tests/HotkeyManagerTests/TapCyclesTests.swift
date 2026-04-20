import XCTest
import WindowEngine
@testable import HotkeyManager

final class TapCyclesTests: XCTestCase {
    func testMiddleLeftFourStepCycle() {
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 1), .leftHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 2), .firstThird)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 3), .grid3MiddleLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 4), .firstTwoThirds)
    }

    func testWrapOnFifthTap() {
        // 4-step cycle wraps to step 1 at tap 5.
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 5), .leftHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleLeft, tapCount: 6), .firstThird)
        // 3-step corner cycle wraps to step 1 at tap 4.
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 4), .topLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 5), .grid3TopLeft)
    }

    func testCornerCyclesThreeSteps() {
        // Top-left
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 1), .topLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 2), .grid3TopLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3TopLeft, tapCount: 3), .topLeftTwoThirds)
        // Top-right
        XCTAssertEqual(TapCycles.resolve(.grid3TopRight, tapCount: 1), .topRight)
        XCTAssertEqual(TapCycles.resolve(.grid3TopRight, tapCount: 2), .grid3TopRight)
        XCTAssertEqual(TapCycles.resolve(.grid3TopRight, tapCount: 3), .topRightTwoThirds)
        // Bottom-left
        XCTAssertEqual(TapCycles.resolve(.grid3BottomLeft, tapCount: 1), .bottomLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomLeft, tapCount: 2), .grid3BottomLeft)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomLeft, tapCount: 3), .bottomLeftTwoThirds)
        // Bottom-right
        XCTAssertEqual(TapCycles.resolve(.grid3BottomRight, tapCount: 1), .bottomRight)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomRight, tapCount: 2), .grid3BottomRight)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomRight, tapCount: 3), .bottomRightTwoThirds)
    }

    func testMiddleCenterThreeStepCycle() {
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleCenter, tapCount: 1), .fullscreen)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleCenter, tapCount: 2), .grid3MiddleCenter)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleCenter, tapCount: 3), .centerThird)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleCenter, tapCount: 4), .fullscreen)
    }

    func testVerticalBandCycles() {
        XCTAssertEqual(TapCycles.resolve(.grid3TopCenter, tapCount: 1), .topHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3TopCenter, tapCount: 2), .topThird)
        XCTAssertEqual(TapCycles.resolve(.grid3TopCenter, tapCount: 3), .grid3TopCenter)
        XCTAssertEqual(TapCycles.resolve(.grid3TopCenter, tapCount: 4), .topTwoThirds)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomCenter, tapCount: 1), .bottomHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomCenter, tapCount: 2), .bottomThird)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomCenter, tapCount: 3), .grid3BottomCenter)
        XCTAssertEqual(TapCycles.resolve(.grid3BottomCenter, tapCount: 4), .bottomTwoThirds)
    }

    func testMiddleRightCycle() {
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleRight, tapCount: 1), .rightHalf)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleRight, tapCount: 2), .lastThird)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleRight, tapCount: 3), .grid3MiddleRight)
        XCTAssertEqual(TapCycles.resolve(.grid3MiddleRight, tapCount: 4), .lastTwoThirds)
    }

    func testNonCycleActionReturnsSelf() {
        XCTAssertEqual(TapCycles.resolve(.leftHalf, tapCount: 1), .leftHalf)
        XCTAssertEqual(TapCycles.resolve(.leftHalf, tapCount: 5), .leftHalf)
        XCTAssertEqual(TapCycles.resolve(.fullscreen, tapCount: 2), .fullscreen)
        XCTAssertEqual(TapCycles.resolve(.undo, tapCount: 3), .undo)
    }

}
