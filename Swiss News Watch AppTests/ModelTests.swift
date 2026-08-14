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
    
    func testEveryDefaultCategoryResolvesAgainstAvailable() {
        let availableIds = Set(NewsCategory.available.map(\.id))
        let dangling = NewsCategory.defaultCategories.subtracting(availableIds)

        XCTAssertTrue(
            dangling.isEmpty,
            "defaultCategories references ids that do not exist in available: \(dangling.sorted())"
        )
    }

    func testCategoryIdsAreUnique() {
        let ids = NewsCategory.available.map(\.id)
        let duplicates = Dictionary(grouping: ids, by: { $0 }).filter { $0.value.count > 1 }.keys

        XCTAssertTrue(duplicates.isEmpty, "Duplicate category ids: \(duplicates.sorted())")
    }

    func testEveryCategoryHasAValidFeedURL() {
        for category in NewsCategory.available {
            XCTAssertNotNil(URL(string: category.feedURL), "\(category.id) has an unparseable feedURL")
            XCTAssertFalse(
                category.feedURL.dropFirst("https://".count).contains("//"),
                "\(category.id) has a doubled slash in its path: \(category.feedURL)"
            )
        }
    }

    func testSettingsDefaultValues() {
        let settings = Settings()
        XCTAssertEqual(settings.cutoffHours, 48.0)
        XCTAssertFalse(settings.selectedCategories.isEmpty)
        XCTAssertFalse(settings.selectedSources.isEmpty)
    }
} 
