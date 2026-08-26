import AppKit
import ApplicationServices
import Foundation
import WindowEngine

/// Capture and restore of window layouts via the Accessibility API.
///
/// AX only exposes windows on the currently visible Space of each display —
/// windows parked on hidden Spaces are unreachable (macOS provides no public
/// API). Both capture and restore therefore operate on "what you can see".
public enum LayoutEngine {
    public struct RestoreOutcome: Equatable, Sendable {
        public var moved = 0
        public var alreadyInPlace = 0
        /// Saved records with no live counterpart (app quit, window closed,
        /// or the window lives on a hidden Space right now).
        public var unmatched = 0

        public init() {}
    }

    /// Snapshot every visible, standard, non-minimized window of every regular
    /// app (except WindowKit itself).
    public static func captureRecords() -> [WindowRecord] {
        captureLive().map(\.record)
    }

    public static func makeProfile(name: String) -> LayoutProfile {
        LayoutProfile(
            name: name,
            signature: .current(),
            windows: captureRecords()
        )
    }

    @discardableResult
    public static func restore(_ profile: LayoutProfile) -> RestoreOutcome {
        let live = captureLive()
        let assignments = LayoutMatcher.plan(
            records: profile.windows,
            live: live.map(\.record)
        )
        var outcome = RestoreOutcome()
        for assignment in assignments {
            let target = profile.windows[assignment.recordIndex].frame
            let (record, window) = live[assignment.liveIndex]
            if LayoutMatcher.needsMove(current: record.frame, target: target) {
                window.setFrame(target)
                outcome.moved += 1
            } else {
                outcome.alreadyInPlace += 1
            }
        }
        outcome.unmatched = profile.windows.count - assignments.count
        return outcome
    }

    // MARK: - Live enumeration

    private static func captureLive() -> [(record: WindowRecord, window: AXWindow)] {
        let ownPid = ProcessInfo.processInfo.processIdentifier
        var out: [(record: WindowRecord, window: AXWindow)] = []

        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != ownPid }

        for app in apps {
            let bundleID = app.bundleIdentifier ?? "pid.\(app.processIdentifier)"
            let appName = app.localizedName ?? bundleID
            for window in AXWindow.windows(pid: app.processIdentifier) {
                guard !window.isMinimized(),
                      let frame = window.frame(),
                      frame.width > 1, frame.height > 1
                else { continue }
                // Standard windows only; dialogs/panels follow their app and
                // restoring them causes more weirdness than it fixes. A nil
                // subrole (some non-AppKit apps) is treated as standard.
                if let subrole = window.subrole(),
                   subrole != (kAXStandardWindowSubrole as String) { continue }
                out.append((
                    record: WindowRecord(
                        bundleID: bundleID,
                        appName: appName,
                        title: window.title() ?? "",
                        frame: frame
                    ),
                    window: window
                ))
            }
        }
        return out
    }
}
