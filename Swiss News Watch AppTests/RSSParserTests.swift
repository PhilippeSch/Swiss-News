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
    func testTimeFilteringNews() async throws {
        // Set a 24-hour filter
        settings.cutoffHours = 24.0
        
        // Create test data with articles of different ages
        let oldArticle = createTestArticle(hoursAgo: 48)
        let newArticle = createTestArticle(hoursAgo: 12)
        let mockData = createMockRSSFeed([oldArticle, newArticle])
        
        let items = try await parseTestFeed(mockData)
        
        XCTAssertEqual(items.count, 1, "Should only include articles within time filter")
        XCTAssertEqual(items.first?.title, "New Article", "Should keep recent article")
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
    
    // Helper methods
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