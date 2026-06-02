import ApplicationServices
import XCTest

@testable import PermissionsCoordinator

/// Pins the AX-probe → trust-health mapping.
///
/// Regression guard for the bug where `kAXErrorCannotComplete` (a busy/
/// unresponsive *focused app*, e.g. Discord mid-call) was misread as a stale
/// Accessibility grant, producing a false "grant is out of date" warning that
/// flapped and disarmed hotkeys. Only `kAXErrorAPIDisabled` may read unhealthy.
final class TrustCanaryTests: XCTestCase {
    func testApiDisabledIsTheOnlyUnhealthyResult() {
        XCTAssertFalse(TrustCanary.isHealthy(probeError: .apiDisabled))
    }

    func testSuccessIsHealthy() {
        XCTAssertTrue(TrustCanary.isHealthy(probeError: .success))
    }

    func testNoValueIsHealthy() {
        XCTAssertTrue(TrustCanary.isHealthy(probeError: .noValue))
    }

    func testBusyOrUnresponsiveAppIsHealthy() {
        // kAXErrorCannotComplete == "messaging failed … or the application is
        // busy or unresponsive" — a per-app condition, never our grant's state.
        XCTAssertTrue(TrustCanary.isHealthy(probeError: .cannotComplete))
    }

    func testNotImplementedIsHealthy() {
        XCTAssertTrue(TrustCanary.isHealthy(probeError: .notImplemented))
    }
}
