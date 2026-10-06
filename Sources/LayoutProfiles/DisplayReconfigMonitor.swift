import AppKit
import Foundation

/// Debounced observer for display arrangement changes (monitor sleep/wake,
/// cable re-plug, resolution change). macOS fires a burst of
/// `didChangeScreenParametersNotification`s while displays settle, and keeps
/// shuffling windows for a moment after the last one — hence the settle delay
/// before `onSettled` runs.
public final class DisplayReconfigMonitor {
    public var onSettled: (() -> Void)?

    private let settleDelay: TimeInterval
    private var pending: DispatchWorkItem?
    private var observer: NSObjectProtocol?

    public init(settleDelay: TimeInterval = 3.0) {
        self.settleDelay = settleDelay
    }

    deinit {
        stop()
    }

    public func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleSettle()
        }
    }

    public func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        pending?.cancel()
        pending = nil
    }

    private func scheduleSettle() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.pending = nil
            self?.onSettled?()
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + settleDelay, execute: work)
    }
}
