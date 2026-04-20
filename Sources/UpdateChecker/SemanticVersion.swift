import Foundation

/// Lightweight numeric semver used only for "is the remote tag newer than ours?"
/// Accepts strings like "0.2.5", "v0.2.5", "1.0.0-beta" (pre-release suffix is dropped).
/// Returns nil if the string has no numeric components.
public struct SemanticVersion: Comparable, Equatable, Sendable {
    public let components: [Int]

    public init?(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let stripped = trimmed.hasPrefix("v") ? String(trimmed.dropFirst()) : trimmed
        let core = stripped.split(separator: "-", maxSplits: 1).first.map(String.init) ?? stripped
        let parsed = core.split(separator: ".").compactMap { Int($0) }
        guard !parsed.isEmpty else { return nil }
        self.components = parsed
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        for (l, r) in zip(lhs.components, rhs.components) {
            if l != r { return l < r }
        }
        return lhs.components.count < rhs.components.count
    }
}
