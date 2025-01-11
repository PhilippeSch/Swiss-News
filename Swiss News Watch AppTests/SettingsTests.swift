import XCTest
@testable import Swiss_News_Watch_App

final class SettingsTests: XCTestCase {
    var settings: Settings!
    
    override func setUp() {
        super.setUp()
        settings = Settings()
    }
    
    func testCategorySelection() {
        let categoryId = "test_category"
        settings.selectedCategories.insert(categoryId)
        XCTAssertTrue(settings.selectedCategories.contains(categoryId))
        
        settings.selectedCategories.remove(categoryId)
        XCTAssertFalse(settings.selectedCategories.contains(categoryId))
    }
    
    func testBatchUpdates() {
        settings.beginBatchUpdate()
        settings.selectedCategories.insert("test1")
        settings.selectedCategories.insert("test2")
        settings.endBatchUpdate()
        
        XCTAssertTrue(settings.selectedCategories.contains("test1"))
        XCTAssertTrue(settings.selectedCategories.contains("test2"))
    }
    
    func testSettingsSessionChanges() {
        settings.beginSettingsSession()
        let originalCount = settings.selectedCategories.count
        
        settings.selectedCategories.insert("test_category")
        settings.commitSettingsChanges()
        
        XCTAssertEqual(settings.selectedCategories.count, originalCount + 1)
    }
} 