import CoreGraphics
import Foundation

public final class UndoStack {
    public struct Snapshot: Equatable, Sendable {
        public let frame: CGRect
        public init(frame: CGRect) { self.frame = frame }
    }

    private var frames: [Snapshot] = []
    private let limit: Int

    public init(limit: Int = 20) {
        precondition(limit > 0, "UndoStack limit must be positive")
        self.limit = limit
    }

    public var count: Int { frames.count }
    public var isEmpty: Bool { frames.isEmpty }

    public func push(_ snapshot: Snapshot) {
        frames.append(snapshot)
        if frames.count > limit {
            frames.removeFirst(frames.count - limit)
        }
    }

    public func pop() -> Snapshot? {
        frames.popLast()
    }

    public func peek() -> Snapshot? {
        frames.last
    }

    public func clear() {
        frames.removeAll()
    }
}
