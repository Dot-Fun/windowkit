import AppKit
import HotkeyManager
import WindowEngine

/// Owns the numpad "sequence" language. Accumulates ⌃⌥⌘+numpad digit presses
/// into a buffer and commits the resolved region to the focused window when
/// the user releases ⌃⌥⌘ *or* pauses briefly — whichever comes first.
///
/// The pause path makes the feature work even if the global modifier-release
/// monitor is unavailable, so commit never depends on a single mechanism.
@MainActor
final class NumpadGridController {
    private let runner: ActionRunner
    private let pauseSeconds: () -> TimeInterval

    private var buffer: [Int] = []
    private var commitToken = 0
    private var flagsMonitor: Any?

    init(runner: ActionRunner, pauseSeconds: @escaping () -> TimeInterval) {
        self.runner = runner
        self.pauseSeconds = pauseSeconds
    }

    /// Start watching for the ⌃⌥⌘ release that commits a sequence.
    func start() {
        guard flagsMonitor == nil else { return }
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let flags = event.modifierFlags
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Commit as soon as the full ⌃⌥⌘ chord is no longer held.
                if !flags.isSuperset(of: [.control, .option, .command]) {
                    self.commit()
                }
            }
        }
    }

    func stop() {
        if let monitor = flagsMonitor {
            NSEvent.removeMonitor(monitor)
            flagsMonitor = nil
        }
        buffer.removeAll()
        commitToken &+= 1
    }

    /// Append a digit and (re)arm the pause-timer fallback.
    func receive(digit: Int) {
        buffer.append(digit)
        schedulePauseCommit()
    }

    private func schedulePauseCommit() {
        commitToken &+= 1
        let token = commitToken
        let delay = max(0.2, pauseSeconds())
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, token == self.commitToken else { return }
            self.commit()
        }
    }

    /// Resolve the accumulated digits and snap the focused window. Idempotent:
    /// the buffer is consumed, so a redundant trigger (release *and* timer)
    /// no-ops the second time.
    private func commit() {
        guard !buffer.isEmpty else { return }
        let digits = buffer
        buffer.removeAll()
        commitToken &+= 1
        guard let region = NumpadRegionResolver.resolve(digits) else { return }
        runner.perform(region: region)
    }
}
