import XCTest
@testable import Swiss_News_Watch_App

@MainActor
final class RSSParserTests: XCTestCase {
    var parser: RSSFeedParser!
    var settings: Settings!
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        settings = Settings()
        parser = RSSFeedParser(settings: settings)
    }
    
    @MainActor
    func testLoadingState() async throws {
        XCTAssertEqual(parser.state, .idle, "Initial state should be idle")
        
        let task = Task {
            await parser.fetchAllFeeds()
        }
        
        // Give time for state to update
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(parser.state, .loading(lastUpdate: nil), "State should be loading during fetch")
        
        await task.value
    }
    
    func testFetchAllFeeds() async throws {
        // Given
        XCTAssertEqual(parser.state, .idle, "Initial state should be idle")
        
        // When
        let task = Task {
            await parser.fetchAllFeeds()
        }
        
        // Then
        try await Task.sleep(nanoseconds: 100_000_000)  // Wait for state update
        XCTAssertEqual(parser.state, .loading(lastUpdate: nil), "State should be loading during fetch")
        
        await task.value  // Wait for completion
    }
    
    // MARK: - Parse-time derivation

    func testParsesPubDateFromRFC822() async throws {
        let items = try await parseTestFeed(feed(withItemBody: """
            <title>Titel</title>
            <description>Text</description>
            <pubDate>Wed, 10 Jun 2026 14:30:00 +0200</pubDate>
            <link>https://test.com/a</link>
            <guid>g1</guid>
        """))

        var components = DateComponents()
        components.year = 2026; components.month = 6; components.day = 10
        components.hour = 14; components.minute = 30
        components.timeZone = TimeZone(secondsFromGMT: 2 * 3600)
        let expected = Calendar(identifier: .gregorian).date(from: components)

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.pubDate, expected)
    }

    func testCleanDescriptionStripsMarkupAndCollapsesWhitespace() async throws {
        let items = try await parseTestFeed(feed(withItemBody: """
            <title>Titel</title>
            <description>&lt;p&gt;Erster   Satz.&lt;/p&gt;&lt;br/&gt;&lt;p&gt;Zweiter
            Satz.&lt;/p&gt;</description>
            <guid>g1</guid>
        """))

        XCTAssertEqual(items.first?.cleanDescription, "Erster Satz.Zweiter Satz.")
    }

    func testImageUrlPrefersDescriptionImageOverMediaAndEnclosure() async throws {
        let items = try await parseTestFeed(feed(withItemBody: """
            <title>Titel</title>
            <description>&lt;img src="https://cdn.test/from-description.jpg"/&gt;Text</description>
            <media:content url="https://cdn.test/from-media.jpg" type="image/jpeg"/>
            <enclosure url="https://cdn.test/from-enclosure.jpg" type="image/jpeg"/>
            <guid>g1</guid>
        """))

        XCTAssertEqual(items.first?.imageUrl?.absoluteString, "https://cdn.test/from-description.jpg")
    }

    func testImageUrlFallsBackThroughMediaThumbnailAndEnclosure() async throws {
        let mediaThumbnail = try await parseTestFeed(feed(withItemBody: """
            <description>Kein Bild im Text</description>
            <media:thumbnail url="https://cdn.test/thumb.jpg"/>
            <enclosure url="https://cdn.test/enclosure.jpg" type="image/jpeg"/>
            <guid>g1</guid>
        """))
        XCTAssertEqual(mediaThumbnail.first?.imageUrl?.absoluteString, "https://cdn.test/thumb.jpg")

        let enclosureOnly = try await parseTestFeed(feed(withItemBody: """
            <description>Kein Bild im Text</description>
            <enclosure url="https://cdn.test/enclosure.jpg" type="image/jpeg"/>
            <guid>g1</guid>
        """))
        XCTAssertEqual(enclosureOnly.first?.imageUrl?.absoluteString, "https://cdn.test/enclosure.jpg")
    }

    func testImageUrlIsNilWhenFeedCarriesNoImage() async throws {
        let items = try await parseTestFeed(feed(withItemBody: """
            <description>Nur Text</description>
            <guid>g1</guid>
        """))
        XCTAssertNil(items.first?.imageUrl)
    }

    func testWebPImageIsRewrittenToJPEGForWatchOS() async throws {
        let items = try await parseTestFeed(feed(withItemBody: """
            <description>Text</description>
            <media:content url="https://cdn.test/bild.webp" type="image/webp"/>
            <guid>g1</guid>
        """))
        XCTAssertEqual(items.first?.imageUrl?.absoluteString, "https://cdn.test/bild.jpg")
    }

    func testDescriptionNoLongerCarriesSyntheticEnclosure() async throws {
        let items = try await parseTestFeed(feed(withItemBody: """
            <description>Text</description>
            <enclosure url="https://cdn.test/bild.jpg" type="image/jpeg"/>
            <guid>g1</guid>
        """))
        XCTAssertEqual(items.first?.description, "Text")
    }

    // Helper methods
    private func feed(withItemBody itemBody: String) -> Data {
        """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
            <channel>
                <item>
                \(itemBody)
                </item>
            </channel>
        </rss>
        """.data(using: .utf8)!
    }

    private func createTestArticle(hoursAgo: Double) -> (title: String, date: Date) {
        let date = Calendar.current.date(byAdding: .hour, value: -Int(hoursAgo), to: Date()) ?? Date()
        return (hoursAgo > 24 ? "Old Article" : "New Article", date)
    }
    
    private func createMockRSSFeed(_ articles: [(title: String, date: Date)]) -> Data {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        
        let articlesXML = articles.map { article in
            """
            <item>
                <title>\(article.title)</title>
                <description>Test description</description>
                <pubDate>\(dateFormatter.string(from: article.date))</pubDate>
                <link>https://test.com/article</link>
                <guid>test-guid-\(article.title)</guid>
            </item>
            """
        }.joined(separator: "\n")
        
        let rssXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                \(articlesXML)
            </channel>
        </rss>
        """
        
        return rssXML.data(using: .utf8)!
    }
    
    private func parseTestFeed(_ data: Data) async throws -> [NewsItem] {
        let parser = XMLParser(data: data)
        let delegate = RSSParserDelegate()
        parser.delegate = delegate
        
        XCTAssertTrue(parser.parse(), "Should parse valid RSS feed")
        return delegate.newsItems
    }
    
    @MainActor
    override func tearDown() async throws {
        parser = nil
        settings = nil
        try await super.tearDown()
    }
} 
