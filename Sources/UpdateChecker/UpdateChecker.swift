import Foundation
import Combine

@MainActor
public final class UpdateChecker: ObservableObject {
    @Published public private(set) var availableUpdate: GitHubRelease?

    public let currentVersion: String
    private let owner: String
    private let repo: String
    private let fetcher: ReleaseFetcher
    private let pollInterval: TimeInterval
    private var timer: Timer?

    public init(
        currentVersion: String,
        owner: String,
        repo: String,
        fetcher: ReleaseFetcher = GitHubReleaseFetcher(),
        pollInterval: TimeInterval = 6 * 3600
    ) {
        self.currentVersion = currentVersion
        self.owner = owner
        self.repo = repo
        self.fetcher = fetcher
        self.pollInterval = pollInterval
    }

    public func start() {
        check()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
    }

    public func check() {
        Task { @MainActor in
            do {
                let release = try await fetcher.fetchLatest(owner: owner, repo: repo)
                availableUpdate = Self.updateIfNewer(current: currentVersion, release: release)
            } catch {
                // Fail silent: intermittent network, GitHub rate limits, offline, etc.
            }
        }
    }

    /// Returns the release if its tag is strictly newer than `current`; otherwise nil.
    /// Exposed for tests.
    public nonisolated static func updateIfNewer(current: String, release: GitHubRelease) -> GitHubRelease? {
        guard
            let here = SemanticVersion(current),
            let there = SemanticVersion(release.tagName)
        else { return nil }
        return there > here ? release : nil
    }
}
