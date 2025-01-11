import XCTest
@testable import Swiss_News_Watch_App

final class ModelTests: XCTestCase {
    func testNewsSourceInitialization() {
        let source = NewsSource(id: "test", name: "Test Source", logoName: "test_logo", order: 1)
        XCTAssertEqual(source.id, "test")
        XCTAssertEqual(source.name, "Test Source")
        XCTAssertEqual(source.order, 1)
    }
    
    func testNewsCategoryInitialization() {
        let category = NewsCategory(
            id: "test_news_all",
            title: "Test News",
            feedURL: "https://test.com/feed",
            group: .news,
            sourceId: "test"
        )
        XCTAssertEqual(category.id, "test_news_all")
        XCTAssertEqual(category.group, .news)
    }
    
    func testSettingsDefaultValues() {
        let settings = Settings()
        XCTAssertEqual(settings.cutoffHours, 48.0)
        XCTAssertFalse(settings.selectedCategories.isEmpty)
        XCTAssertFalse(settings.selectedSources.isEmpty)
    }
} 