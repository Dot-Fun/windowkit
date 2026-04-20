import XCTest
@testable import UpdateChecker

final class UpdateCheckerTests: XCTestCase {
    private let sampleRelease = GitHubRelease(
        tagName: "v0.2.6",
        htmlURL: URL(string: "https://github.com/Dot-Fun/windowkit/releases/tag/v0.2.6")!,
        name: "v0.2.6",
        body: "release notes"
    )

    func testReturnsReleaseWhenRemoteIsNewer() {
        let result = UpdateChecker.updateIfNewer(current: "0.2.5", release: sampleRelease)
        XCTAssertEqual(result, sampleRelease)
    }

    func testReturnsNilWhenRemoteEqualsLocal() {
        let same = GitHubRelease(
            tagName: "v0.2.5",
            htmlURL: URL(string: "https://example.com")!
        )
        XCTAssertNil(UpdateChecker.updateIfNewer(current: "0.2.5", release: same))
    }

    func testReturnsNilWhenRemoteOlderThanLocal() {
        let old = GitHubRelease(
            tagName: "v0.2.3",
            htmlURL: URL(string: "https://example.com")!
        )
        XCTAssertNil(UpdateChecker.updateIfNewer(current: "0.2.5", release: old))
    }

    func testReturnsNilOnGarbageVersions() {
        let bad = GitHubRelease(
            tagName: "nightly",
            htmlURL: URL(string: "https://example.com")!
        )
        XCTAssertNil(UpdateChecker.updateIfNewer(current: "0.2.5", release: bad))
    }

    func testDecodesGitHubReleaseJSON() throws {
        let json = #"""
        {
            "tag_name": "v0.2.5",
            "html_url": "https://github.com/Dot-Fun/windowkit/releases/tag/v0.2.5",
            "name": "v0.2.5",
            "body": "- reordered taps\n- update checker"
        }
        """#.data(using: .utf8)!
        let release = try JSONDecoder().decode(GitHubRelease.self, from: json)
        XCTAssertEqual(release.tagName, "v0.2.5")
        XCTAssertEqual(release.htmlURL.absoluteString, "https://github.com/Dot-Fun/windowkit/releases/tag/v0.2.5")
    }
}
