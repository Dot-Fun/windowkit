import Combine
import Foundation

/// UserDefaults-backed collection of saved layouts. Mutations persist
/// immediately; there is no separate save step to forget.
public final class LayoutProfileStore: ObservableObject {
    private static let defaultsKey = "WindowKit.layoutProfiles.v1"

    @Published public private(set) var profiles: [LayoutProfile]

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([LayoutProfile].self, from: data) {
            self.profiles = decoded
        } else {
            self.profiles = []
        }
    }

    public func add(_ profile: LayoutProfile) {
        profiles.append(profile)
        persist()
    }

    public func remove(id: UUID) {
        profiles.removeAll { $0.id == id }
        persist()
    }

    public func rename(id: UUID, to name: String) {
        mutate(id: id) { $0.name = name }
    }

    public func setAutoRestore(id: UUID, _ enabled: Bool) {
        mutate(id: id) { $0.autoRestore = enabled }
    }

    /// "Update with current windows": re-snapshot an existing profile in place,
    /// keeping its identity, name, and auto-restore setting.
    public func replaceWindows(id: UUID, windows: [WindowRecord], signature: DisplaySignature) {
        mutate(id: id) {
            $0.windows = windows
            $0.signature = signature
            $0.savedAt = Date()
        }
    }

    /// The profile auto-restore should apply for `signature`, or nil. When
    /// several qualify (the per-Space-profiles case), the most recently saved
    /// wins — restoring them all would fight over the same visible windows.
    public func autoRestoreProfile(matching signature: DisplaySignature) -> LayoutProfile? {
        profiles
            .filter { $0.autoRestore && $0.signature.matches(signature) }
            .max { $0.savedAt < $1.savedAt }
    }

    private func mutate(id: UUID, _ change: (inout LayoutProfile) -> Void) {
        guard let idx = profiles.firstIndex(where: { $0.id == id }) else { return }
        change(&profiles[idx])
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }
}
