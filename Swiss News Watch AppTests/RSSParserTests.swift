import XCTest
import Combine
@testable import Swiss_News_Watch_App

@MainActor
final class RSSParserTests: XCTestCase {
    var parser: RSSFeedParser!
    var settings: Settings!
    
    private var cancellables: Set<AnyCancellable> = []

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        StubURLProtocol.reset()
        StubURLProtocol.responder = { _ in (200, FeedFixture.feed()) }
        settings = Settings()
        // Exactly one feed, so assertions are about the parser and not the
        // user's persisted category selection.
        settings.selectedSources = ["srf"]
        settings.selectedCategories = ["srf_news_all"]
        parser = RSSFeedParser(settings: settings, urlSession: StubURLProtocol.makeSession())
    }

    @MainActor
    override func tearDown() async throws {
        cancellables.removeAll()
        StubURLProtocol.reset()
        parser = nil
        settings = nil
        try await super.tearDown()
    }

    // MARK: - Loading state

    func testFetchAllFeedsMovesThroughLoadingToLoaded() async throws {
        XCTAssertEqual(parser.state, .idle, "Initial state should be idle")

        // Record every state the UI would observe, rather than sampling after a
        // sleep — sampling races with how fast the fetch completes.
        let recorder = StateRecorder()
        parser.$state
            .sink { recorder.append($0) }
            .store(in: &cancellables)

        await parser.fetchAllFeeds()

        XCTAssertEqual(recorder.states.first, .idle)
        XCTAssertTrue(
            recorder.states.contains(.loading(lastUpdate: nil)),
            "Should publish a loading state during the fetch, got \(recorder.states)"
        )
        XCTAssertNotNil(parser.state.lastUpdate, "Should finish with a timestamp")
        XCTAssertNil(parser.state.error, "Should finish without error")
    }

    func testFetchAllFeedsPopulatesSelectedCategory() async throws {
        await parser.fetchAllFeeds()

        XCTAssertEqual(parser.newsItems["srf_news_all"]?.count, 2)
        XCTAssertEqual(parser.newsItems["srf_news_all"]?.first?.title, "Artikel 1")
        XCTAssertTrue(parser.loadingCategories.isEmpty, "Loading spinners should clear")
    }

    func testFetchAllFeedsRequestsOnlySelectedCategories() async throws {
        await parser.fetchAllFeeds()

        XCTAssertEqual(StubURLProtocol.requestedURLs.count, 1)
        XCTAssertEqual(
            StubURLProtocol.requestedURLs.first?.absoluteString,
            "https://www.srf.ch/news/bnf/rss/1646"
        )
    }

    func testServerErrorSurfacesAsErrorState() async throws {
        StubURLProtocol.responder = { _ in (500, Data()) }

        await parser.fetchAllFeeds()

        XCTAssertNotNil(parser.state.error, "A 500 should surface as an error state")
    }

    func testNotAcceptableFeedIsSkippedSilently() async throws {
        StubURLProtocol.responder = { _ in (406, Data()) }

        await parser.fetchAllFeeds()

        XCTAssertNil(parser.state.error, "406 feeds are skipped rather than surfaced")
        XCTAssertEqual(parser.newsItems["srf_news_all"], [])
    }

    func testItemsOlderThanCutoffAreFiltered() async throws {
        settings.cutoffHours = 48
        let threeDaysAgo = Date().addingTimeInterval(-72 * 3600)
        StubURLProtocol.responder = { _ in (200, FeedFixture.feed(publishedAt: threeDaysAgo)) }

        await parser.fetchAllFeeds()

        XCTAssertEqual(parser.newsItems["srf_news_all"], [], "Stale items should be filtered out")
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

    private func parseTestFeed(_ data: Data) async throws -> [NewsItem] {
        let parser = XMLParser(data: data)
        let delegate = RSSParserDelegate()
        parser.delegate = delegate

        XCTAssertTrue(parser.parse(), "Should parse valid RSS feed")
        return delegate.newsItems
    }
}

/// Collects published states so a test can assert on the whole transition
/// sequence instead of sampling at one moment.
private final class StateRecorder {
    private(set) var states: [LoadingState] = []

    func append(_ state: LoadingState) {
        states.append(state)
    }
}

