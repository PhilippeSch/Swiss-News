#if DEBUG
import Foundation

/// Puts the app into a known state for UI tests: no welcome screen, a fixed
/// category selection, and canned feeds instead of the live network.
///
/// Debug-only, and inert unless the launch arguments ask for it, so it cannot
/// affect a release build or a normal debug run.
enum UITestSupport {
    static let launchArgument = "-UITesting"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// Categories the tests expect on the home screen, in this order.
    static let categoryIds = [
        "srf_news_all",
        "srf_news_swiss",
        "srf_news_international",
        "srf_news_economy",
        "srf_sport_all",
        "srf_culture_all",
        "srf_knowledge_all"
    ]

    static func prepare() {
        guard isActive else { return }

        let defaults = UserDefaults.standard
        defaults.set(false, forKey: Constants.UserDefaults.firstLaunchKey)
        defaults.set(true, forKey: Constants.UserDefaults.selectedCategoriesInitializedKey)
        defaults.set(48.0, forKey: Constants.UserDefaults.cutoffHoursKey)
        defaults.removeObject(forKey: Constants.UserDefaults.readArticlesKey)

        if let categories = try? JSONEncoder().encode(Set(categoryIds)) {
            defaults.set(categories, forKey: Constants.UserDefaults.selectedCategoriesKey)
        }
        if let sources = try? JSONEncoder().encode(Set(["srf"])) {
            defaults.set(sources, forKey: Constants.UserDefaults.selectedSourcesKey)
        }

        // Start from an empty cache so the first screen is always a fresh fetch.
        let cache = NewsCacheStore()
        Task { await cache.clear() }
    }

    /// A session serving canned feeds, so UI tests never depend on the network.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UITestFeedProtocol.self]
        return URLSession(configuration: configuration)
    }

    /// Number of articles each stubbed category returns.
    static let articlesPerCategory = 4
}

/// Answers every request with a small deterministic feed, or a 1x1 JPEG for
/// image URLs.
final class UITestFeedProtocol: URLProtocol {
    private static let rfc822: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let body = Self.body(for: url)
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func body(for url: URL) -> Data {
        guard !url.absoluteString.contains("/uitest-image") else {
            return jpegPixel
        }

        // Article pages, which ArticleView scrapes with SwiftSoup.
        if url.host == "test.local" {
            return """
            <html><body><article>
                <p>Erster Absatz des Testartikels für die UI-Tests.</p>
                <p>Zweiter Absatz mit weiterem Inhalt.</p>
            </article></body></html>
            """.data(using: .utf8)!
        }

        // Name articles after the feed so each category is distinguishable.
        let slug = url.lastPathComponent
        let items = (1...UITestSupport.articlesPerCategory).map { index in
            """
            <item>
                <title>Testartikel \(slug) Nummer \(index)</title>
                <description>Zusammenfassung des Testartikels \(index) aus Feed \(slug).</description>
                <pubDate>\(rfc822.string(from: Date().addingTimeInterval(Double(-index) * 600)))</pubDate>
                <link>https://test.local/\(slug)/\(index)</link>
                <guid>uitest-\(slug)-\(index)</guid>
                <enclosure url="https://test.local/uitest-image/\(slug)-\(index).jpg" type="image/jpeg"/>
            </item>
            """
        }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
            <channel>
        \(items)
            </channel>
        </rss>
        """.data(using: .utf8)!
    }

    /// Smallest valid JPEG, so image rows resolve without a network hop.
    private static let jpegPixel: Data = Data(base64Encoded: """
    /9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a\
    HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAA\
    AAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==
    """.replacingOccurrences(of: "\\\n", with: ""))!
}
#endif
