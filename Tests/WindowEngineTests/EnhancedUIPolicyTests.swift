import XCTest

@testable import WindowEngine

/// Locks in the enhanced-UI dance decisions that make Electron apps (Discord,
/// Slack, VS Code) move. The live AX calls can't be unit-tested, but the
/// policy that drives them can — and it's the part most likely to regress.
final class EnhancedUIPolicyTests: XCTestCase {
    func testAttributeNamesAreExact() {
        // A typo here silently disables Electron handling (the original bug).
        XCTAssertEqual(AXAttr.enhancedUserInterface, "AXEnhancedUserInterface")
        XCTAssertEqual(AXAttr.manualAccessibility, "AXManualAccessibility")
    }

    func testDanceOnlyWhenEnhancedUIIsOn() {
        XCTAssertTrue(EnhancedUIPolicy.shouldToggle(currentlyEnabled: true))
        XCTAssertFalse(EnhancedUIPolicy.shouldToggle(currentlyEnabled: false))
        // Attribute absent (most AppKit apps) → leave it alone.
        XCTAssertFalse(EnhancedUIPolicy.shouldToggle(currentlyEnabled: nil))
    }

    func testFramePlanOrdering() {
        // EUI on: disable → write → restore, in that exact order.
        XCTAssertEqual(
            EnhancedUIPolicy.framePlan(euiEnabled: true),
            [.disableEnhancedUI, .writeFrame, .restoreEnhancedUI]
        )
        // EUI off/absent: just the write, no toggling.
        XCTAssertEqual(EnhancedUIPolicy.framePlan(euiEnabled: false), [.writeFrame])
    }

    func testFramePlanAlwaysWritesExactlyOnce() {
        for euiEnabled in [true, false] {
            let writes = EnhancedUIPolicy.framePlan(euiEnabled: euiEnabled)
                .filter { $0 == .writeFrame }
            XCTAssertEqual(writes.count, 1)
        }
    }

    func testFramePlanRestoresWheneverItDisables() {
        let plan = EnhancedUIPolicy.framePlan(euiEnabled: true)
        if let disableIdx = plan.firstIndex(of: .disableEnhancedUI) {
            // A restore must come after the disable so EUI is never left off.
            let restoreIdx = plan.firstIndex(of: .restoreEnhancedUI)
            XCTAssertNotNil(restoreIdx)
            XCTAssertGreaterThan(restoreIdx!, disableIdx)
        }
        // When we never disable, we must never restore either.
        let offPlan = EnhancedUIPolicy.framePlan(euiEnabled: false)
        XCTAssertFalse(offPlan.contains(.disableEnhancedUI))
        XCTAssertFalse(offPlan.contains(.restoreEnhancedUI))
    }
}
