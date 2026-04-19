import XCTest
import WindowEngine
@testable import HotkeyManager

@MainActor
final class TapDetectorTests: XCTestCase {
    private final class Clock {
        var now: Date = Date(timeIntervalSince1970: 1_000)
        func advance(_ dt: TimeInterval) { now = now.addingTimeInterval(dt) }
    }

    func testSingleTapReturnsOne() {
        let clock = Clock()
        let detector = TapDetector(clock: { clock.now })
        XCTAssertEqual(detector.register(.leftHalf, window: 0.4), 1)
    }

    func testTwoTapsWithinWindowIncrement() {
        let clock = Clock()
        let detector = TapDetector(clock: { clock.now })
        XCTAssertEqual(detector.register(.grid3TopCenter, window: 0.4), 1)
        clock.advance(0.2)
        XCTAssertEqual(detector.register(.grid3TopCenter, window: 0.4), 2)
    }

    func testTwoTapsOutsideWindowReset() {
        let clock = Clock()
        let detector = TapDetector(clock: { clock.now })
        XCTAssertEqual(detector.register(.grid3TopCenter, window: 0.4), 1)
        clock.advance(0.5)
        XCTAssertEqual(detector.register(.grid3TopCenter, window: 0.4), 1)
    }

    func testFiveConsecutiveTapsWithinWindow() {
        let clock = Clock()
        let detector = TapDetector(clock: { clock.now })
        var counts: [Int] = []
        for _ in 0..<5 {
            counts.append(detector.register(.grid3MiddleLeft, window: 0.4))
            clock.advance(0.1)
        }
        XCTAssertEqual(counts, [1, 2, 3, 4, 5])
    }

    func testDifferentActionsTrackedIndependently() {
        let clock = Clock()
        let detector = TapDetector(clock: { clock.now })
        XCTAssertEqual(detector.register(.leftHalf, window: 0.4), 1)
        clock.advance(0.1)
        XCTAssertEqual(detector.register(.rightHalf, window: 0.4), 1)
        clock.advance(0.1)
        XCTAssertEqual(detector.register(.leftHalf, window: 0.4), 2)
    }

    func testResetClearsCounts() {
        let clock = Clock()
        let detector = TapDetector(clock: { clock.now })
        _ = detector.register(.leftHalf, window: 0.4)
        detector.reset()
        clock.advance(0.1)
        XCTAssertEqual(detector.register(.leftHalf, window: 0.4), 1)
    }
}
