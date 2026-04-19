import Foundation
import PreferencesStore
import WindowEngine

public final class HotkeyManager {
    public typealias Handler = (WindowAction) -> Void

    private var handler: Handler?

    public init() {}

    public func register(bindings: [WindowAction: Shortcut], onTrigger: @escaping Handler) {
        // TODO: implement Carbon hotkey registration in hotkey-dev task.
        self.handler = onTrigger
    }

    public func unregisterAll() {
        // TODO: implement in hotkey-dev task.
    }
}
