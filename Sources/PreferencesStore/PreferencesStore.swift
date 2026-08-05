import Combine
import Foundation
import WindowEngine

public struct Conflict: Equatable, Sendable {
    public let existingAction: WindowAction
    public let shortcut: Shortcut
}

public final class PreferencesStore: ObservableObject {
    private static let defaultsKey = "WindowKit.bindings.v1"

    @Published public private(set) var bindings: [WindowAction: Shortcut]

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.bindings = DefaultBindings.spectacle
        load()
    }

    public func load() {
        guard
            let data = defaults.data(forKey: Self.defaultsKey),
            let decoded = try? Self.decode(data)
        else {
            bindings = DefaultBindings.spectacle
            return
        }
        bindings = decoded
    }

    public func save() {
        guard let data = try? Self.encode(bindings) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    /// Assigns `shortcut` to `action`. If another action already owns an
    /// equivalent shortcut, returns `Conflict` describing it and leaves
    /// bindings unchanged. Pass `nil` to clear the shortcut for `action`.
    @discardableResult
    public func set(_ shortcut: Shortcut?, for action: WindowAction) -> Conflict? {
        guard let shortcut else {
            bindings.removeValue(forKey: action)
            commit()
            return nil
        }
        if let existing = bindings.first(where: { $0.key != action && $0.value == shortcut }) {
            return Conflict(existingAction: existing.key, shortcut: shortcut)
        }
        bindings[action] = shortcut
        commit()
        return nil
    }

    public func restoreDefaults() {
        bindings = DefaultBindings.spectacle
        commit()
    }

    public func exportJSON() -> Data {
        (try? Self.encode(bindings, pretty: true)) ?? Data()
    }

    public func importJSON(_ data: Data) throws {
        bindings = try Self.decode(data)
        commit()
    }

    private func commit() {
        save()
    }

    // Encode via [String: Shortcut] so JSON is a proper keyed object instead
    // of Swift's default [key, value, ...] array form for non-string enum keys.
    private static func encode(_ bindings: [WindowAction: Shortcut], pretty: Bool = false) throws -> Data {
        let stringKeyed = Dictionary(uniqueKeysWithValues: bindings.map { ($0.key.rawValue, $0.value) })
        let encoder = JSONEncoder()
        if pretty { encoder.outputFormatting = [.prettyPrinted, .sortedKeys] }
        return try encoder.encode(stringKeyed)
    }

    private static func decode(_ data: Data) throws -> [WindowAction: Shortcut] {
        let stringKeyed = try JSONDecoder().decode([String: Shortcut].self, from: data)
        var out: [WindowAction: Shortcut] = [:]
        for (raw, shortcut) in stringKeyed {
            guard let action = WindowAction(rawValue: raw) else { continue }
            out[action] = shortcut
        }
        return out
    }
}
