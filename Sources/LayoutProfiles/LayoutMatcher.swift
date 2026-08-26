import CoreGraphics
import Foundation

/// Pure pairing of saved window records to live windows. Kept free of AX so
/// the tricky part — deciding *which* live window gets *which* saved frame —
/// is unit-testable.
public enum LayoutMatcher {
    public struct Assignment: Equatable, Sendable {
        public var recordIndex: Int
        public var liveIndex: Int

        public init(recordIndex: Int, liveIndex: Int) {
            self.recordIndex = recordIndex
            self.liveIndex = liveIndex
        }
    }

    /// Pair each saved record with at most one live window.
    ///
    /// Windows never match across apps. Within an app, exact title matches win
    /// first (greedy, in saved order); leftovers pair up positionally — saved
    /// order against live (AX list) order. The positional fallback matters for
    /// terminals, whose titles track the running command and rarely survive a
    /// day, but where any 1:1 assignment of N same-app windows to N saved
    /// frames restores the layout.
    public static func plan(records: [WindowRecord], live: [WindowRecord]) -> [Assignment] {
        var out: [Assignment] = []
        let liveByBundle = Dictionary(grouping: live.indices, by: { live[$0].bundleID })
        let recordsByBundle = Dictionary(grouping: records.indices, by: { records[$0].bundleID })

        for (bundle, recordIndices) in recordsByBundle {
            guard var remainingLive = liveByBundle[bundle] else { continue }
            var unmatchedRecords: [Int] = []

            for r in recordIndices {
                let title = records[r].title
                if !title.isEmpty,
                   let pos = remainingLive.firstIndex(where: { live[$0].title == title }) {
                    out.append(Assignment(recordIndex: r, liveIndex: remainingLive.remove(at: pos)))
                } else {
                    unmatchedRecords.append(r)
                }
            }
            for (r, l) in zip(unmatchedRecords, remainingLive) {
                out.append(Assignment(recordIndex: r, liveIndex: l))
            }
        }
        // Dictionary iteration order is unstable; sort so output is deterministic.
        return out.sorted { $0.recordIndex < $1.recordIndex }
    }

    /// Whether a restore should actually write. Sub-point differences are AX
    /// rounding noise, not drift worth a frame write (which can flash/animate).
    public static func needsMove(current: CGRect, target: CGRect, epsilon: CGFloat = 1.0) -> Bool {
        abs(current.origin.x - target.origin.x) > epsilon
            || abs(current.origin.y - target.origin.y) > epsilon
            || abs(current.width - target.width) > epsilon
            || abs(current.height - target.height) > epsilon
    }
}
