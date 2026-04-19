import Foundation
import WindowEngine

/// Counts consecutive taps of the same `WindowAction` within a configurable
/// time window. Pure logic with an injectable clock so tests don't need to
/// sleep; wrap-on-last-step is `TapCycles.resolve`'s job — this just counts.
@MainActor
public final class TapDetector {
    private var last: [WindowAction: (at: Date, count: Int)] = [:]
    private let clock: () -> Date

    public init(clock: @escaping () -> Date = Date.init) {
        self.clock = clock
    }

    /// Returns the 1-based tap count for `action`. Resets to 1 when the gap
    /// since the last fire exceeds `window`.
    @discardableResult
    public func register(_ action: WindowAction, window: TimeInterval) -> Int {
        let now = clock()
        let count: Int
        if let prev = last[action], now.timeIntervalSince(prev.at) <= window {
            count = prev.count + 1
        } else {
            count = 1
        }
        last[action] = (now, count)
        return count
    }

    public func reset() {
        last.removeAll()
    }
}
