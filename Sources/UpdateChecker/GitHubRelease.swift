import Foundation

public struct GitHubRelease: Codable, Equatable, Sendable {
    public let tagName: String
    public let htmlURL: URL
    public let name: String?
    public let body: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case name
        case body
    }

    public init(tagName: String, htmlURL: URL, name: String? = nil, body: String? = nil) {
        self.tagName = tagName
        self.htmlURL = htmlURL
        self.name = name
        self.body = body
    }
}
