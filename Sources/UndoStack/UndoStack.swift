import CoreGraphics
import Foundation

public final class UndoStack {
    public struct Snapshot {
        public let frame: CGRect
        public init(frame: CGRect) { self.frame = frame }
    }

    private var frames: [Snapshot] = []
    private let limit: Int

    public init(limit: Int = 10) {
        self.limit = limit
    }

    public func push(_ snapshot: Snapshot) {
        // TODO: implement in engine-dev task.
    }

    public func pop() -> Snapshot? {
        // TODO: implement in engine-dev task.
        return nil
    }
}
