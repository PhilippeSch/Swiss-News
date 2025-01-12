import XCTest

final class SwissNewsUITests: XCTestCase {
    var app: XCUIApplication!
    let timeout: TimeInterval = 10
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
        
        // Wait for initial load
        waitForAppReady()
    }
    
    private func waitForAppReady() {
        let headerTitle = app.staticTexts["Swiss News"]
        XCTAssertTrue(headerTitle.waitForExistence(timeout: timeout), "App header should exist")
    }
    
    func testSettingsNavigation() throws {
        // Find settings button without scrolling first
        let settingsButton = app.buttons["settingsButton"]
        
        // If button isn't immediately visible, scroll to find it
        if !settingsButton.isHittable {
            // Find the main scroll view
            let mainList = app.collectionViews.firstMatch // List is actually a UICollectionView
            
            // Scroll until we find the button or reach bottom
            var attempts = 0
            while !settingsButton.isHittable && attempts < 5 {
                mainList.swipeUp()
                attempts += 1
            }
        }
        
        // Verify and tap button
        XCTAssertTrue(settingsButton.waitForExistence(timeout: timeout), "Settings button should exist")
        XCTAssertTrue(settingsButton.isHittable, "Settings button should be hittable")
        settingsButton.tap()
        
        // Verify navigation
        let settingsTitle = app.navigationBars["Einstellungen"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: timeout), "Settings title should exist")
    }
    
    func testArticleInteraction() throws {
        // Wait for content to load and find first news category
        let categoryRow = app.buttons.matching(identifier: "categoryRow_srf_news_all").firstMatch
        XCTAssertTrue(categoryRow.waitForExistence(timeout: timeout), "News category should exist")
        categoryRow.tap()
        
        // Wait for article list content
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: timeout), "Article scroll view should exist")
        
        // Look for any "Lesen" button
        let readButton = scrollView.buttons["Lesen"].firstMatch
        guard readButton.waitForExistence(timeout: timeout) else {
            XCTFail("No read buttons found")
            return
        }
        readButton.tap()
        
        // Verify article detail view
        let articleView = app.scrollViews["articleDetailView"]
        XCTAssertTrue(articleView.waitForExistence(timeout: timeout), "Article detail view should exist")
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
} 
