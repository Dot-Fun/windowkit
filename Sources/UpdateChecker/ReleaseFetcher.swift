import Foundation

public protocol ReleaseFetcher: Sendable {
    func fetchLatest(owner: String, repo: String) async throws -> GitHubRelease
}

public struct GitHubReleaseFetcher: ReleaseFetcher {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchLatest(owner: String, repo: String) async throws -> GitHubRelease {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("WindowKit", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }
}
