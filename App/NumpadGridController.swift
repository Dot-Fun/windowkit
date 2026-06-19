import AppKit
import HotkeyManager
import WindowEngine

/// Owns the numpad "sequence" language. Accumulates ⌃⌥⌘+numpad digit presses
/// into a buffer and commits the resolved region to the focused window when
/// the user releases ⌃⌥⌘ *or* pauses briefly — whichever comes first.
///
/// Also drives the on-screen grid overlay via the `onShowOverlay` /
/// `onUpdateOverlay` / `onHideOverlay` hooks: the overlay appears on a
/// deliberate ⌃⌥⌘ hold (or the first numpad tap) and previews the region live.
/// Hooks are closures so this controller stays free of view dependencies.
@MainActor
final class NumpadGridController {
    private let runner: ActionRunner
    private let pauseSeconds: () -> TimeInterval

    var onShowOverlay: (() -> Void)?
    var onUpdateOverlay: ((GridRegion?) -> Void)?
    var onHideOverlay: (() -> Void)?

    private var buffer: [Int] = []
    private var commitToken = 0
    private var flagsMonitor: Any?

    // Overlay / hold state.
    private var chordHeld = false
    private var overlayShown = false
    private var showToken = 0
    /// Delay before a bare ⌃⌥⌘ hold shows the grid, so quick ⌃⌥⌘+arrow/bracket
    /// chords (thirds, displays) don't flash it. A numpad tap shows it at once.
    private let showDelay: TimeInterval = 0.3

    init(runner: ActionRunner, pauseSeconds: @escaping () -> TimeInterval) {
        self.runner = runner
        self.pauseSeconds = pauseSeconds
    }

    /// Start watching ⌃⌥⌘ press/release: shows the overlay on hold, commits on release.
    func start() {
        guard flagsMonitor == nil else { return }
        flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            let held = event.modifierFlags.isSuperset(of: [.control, .option, .command])
            Task { @MainActor [weak self] in
                self?.handleChord(held: held)
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
        showToken &+= 1
        chordHeld = false
        hideOverlay()
    }

    /// Append a digit, show/refresh the overlay, and (re)arm the pause fallback.
    func receive(digit: Int) {
        buffer.append(digit)
        if !overlayShown { showOverlay() } // first tap shows it immediately
        refreshOverlay()
        schedulePauseCommit()
    }

    // MARK: - Chord (modifier) tracking

    private func handleChord(held: Bool) {
        if held, !chordHeld {
            chordHeld = true
            scheduleShowOverlay()
        } else if !held, chordHeld {
            chordHeld = false
            showToken &+= 1 // cancel any pending bare-hold show
            commit()        // commit if a sequence is buffered (also hides)
            hideOverlay()   // covers the held-with-no-digits case
        }
    }

    // MARK: - Overlay

    private func scheduleShowOverlay() {
        showToken &+= 1
        let token = showToken
        DispatchQueue.main.asyncAfter(deadline: .now() + showDelay) { [weak self] in
            guard let self, token == self.showToken, self.chordHeld else { return }
            self.showOverlay()
        }
    }

    private func showOverlay() {
        guard !overlayShown else { return }
        overlayShown = true
        onShowOverlay?()
        refreshOverlay()
    }

    private func refreshOverlay() {
        guard overlayShown else { return }
        onUpdateOverlay?(NumpadRegionResolver.resolve(buffer))
    }

    private func hideOverlay() {
        guard overlayShown else { return }
        overlayShown = false
        onHideOverlay?()
    }

    // MARK: - Commit

    private func schedulePauseCommit() {
        commitToken &+= 1
        let token = commitToken
        let delay = max(0.2, pauseSeconds())
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, token == self.commitToken else { return }
            self.commit()
        }
    }

    /// Resolve the accumulated digits, hide the overlay, and snap the focused
    /// window. Idempotent: the buffer is consumed, so release+timer is safe.
    private func commit() {
        guard !buffer.isEmpty else { return }
        let digits = buffer
        buffer.removeAll()
        commitToken &+= 1
        hideOverlay()
        if let region = NumpadRegionResolver.resolve(digits) {
            runner.perform(region: region)
        }
    }
}
