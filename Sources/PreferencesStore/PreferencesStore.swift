import Foundation
import WindowEngine

public final class PreferencesStore {
    public private(set) var bindings: [WindowAction: Shortcut] = [:]

    public init() {}

    public func load() {
        // TODO: implement in hotkey-dev task (UserDefaults-backed).
    }

    public func save() {
        // TODO: implement in hotkey-dev task.
    }

    public func setShortcut(_ shortcut: Shortcut?, for action: WindowAction) {
        // TODO: implement in hotkey-dev task.
    }

    public static func defaults() -> [WindowAction: Shortcut] {
        // TODO: implement in hotkey-dev task.
        return [:]
    }
}
