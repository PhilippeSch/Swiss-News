import Foundation

struct NewsItem: Identifiable, Equatable {
    let title: String
    let description: String
    /// HTML stripped and whitespace collapsed, derived once at init.
    let cleanDescription: String
    let pubDate: Date
    let link: String
    let guid: String
    /// Article image, already normalised for watchOS. Derived once at init.
    let imageUrl: URL?

    var id: String { guid }

    init(title: String, description: String, pubDate: Date, link: String, guid: String, imageUrl: URL? = nil) {
        self.title = title
        self.description = description
        self.cleanDescription = Self.stripHTML(from: description)
        self.pubDate = pubDate
        self.link = link
        self.guid = guid
        self.imageUrl = imageUrl.map(Self.watchCompatibleURL)
    }

    private static let htmlTagRegex = try! NSRegularExpression(pattern: "<[^>]+>")
    private static let whitespaceRegex = try! NSRegularExpression(pattern: "\\s+")

    /// Removes HTML markup and collapses runs of whitespace into single spaces.
    static func stripHTML(from description: String) -> String {
        let range = NSRange(description.startIndex..., in: description)
        let withoutTags = htmlTagRegex.stringByReplacingMatches(in: description, range: range, withTemplate: "")
        let collapsed = whitespaceRegex.stringByReplacingMatches(
            in: withoutTags,
            range: NSRange(withoutTags.startIndex..., in: withoutTags),
            withTemplate: " "
        )
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// watchOS cannot decode WebP, so ask the CDN for the JPEG variant instead.
    private static func watchCompatibleURL(_ url: URL) -> URL {
        let urlString = url.absoluteString
        guard urlString.hasSuffix(".webp") else { return url }
        let jpgUrlString = urlString.replacingOccurrences(of: ".webp", with: ".jpg")
        return URL(string: jpgUrlString) ?? url
    }

    static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
        lhs.guid == rhs.guid &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.pubDate == rhs.pubDate &&
        lhs.imageUrl == rhs.imageUrl
    }
}
