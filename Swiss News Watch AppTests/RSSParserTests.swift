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
    override func tearDown() async throws {
        parser = nil
        settings = nil
        try await super.tearDown()
    }
    
    @MainActor
    func testParsingValidRSSFeed() async throws {
        // Test with a mock RSS feed
        let mockData = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
            <channel>
                <item>
                    <title>Test Article</title>
                    <description>Test Description</description>
                    <pubDate>Wed, 21 Feb 2024 12:00:00 +0100</pubDate>
                    <link>https://test.com/article</link>
                </item>
            </channel>
        </rss>
        """.data(using: .utf8)!
        
        let delegate = RSSParserDelegate()
        let xmlParser = XMLParser(data: mockData)
        xmlParser.delegate = delegate
        
        XCTAssertTrue(xmlParser.parse())
        XCTAssertEqual(delegate.newsItems.count, 1)
        XCTAssertEqual(delegate.newsItems.first?.title, "Test Article")
    }
    
    @MainActor
    func testLoadingStateManagement() async throws {
        XCTAssertEqual(parser.state, .idle)
        
        await parser.fetchAllFeeds()
        
        // Test that state changes appropriately
        if case .loaded = parser.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Parser should be in loaded state")
        }
    }
    
    // Add more tests for error handling
    @MainActor
    func testInvalidURLHandling() async throws {
        // Modify parser to use an invalid URL
        let invalidCategory = NewsCategory(
            id: "invalid",
            title: "Invalid",
            feedURL: "invalid://url",
            group: .news,
            sourceId: "test"
        )
        
        settings.selectedCategories.insert(invalidCategory.id)
        settings.selectedSources.insert(invalidCategory.sourceId)
        
        await parser.fetchAllFeeds()
        
        // Should handle invalid URL gracefully
        if case .loaded = parser.state {
            XCTAssertTrue(true, "Parser should complete even with invalid URLs")
        } else {
            XCTFail("Parser should handle invalid URLs gracefully")
        }
    }
} 