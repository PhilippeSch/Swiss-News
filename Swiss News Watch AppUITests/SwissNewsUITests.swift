import XCTest

final class SwissNewsUITests: XCTestCase {
    var app: XCUIApplication!
    let timeout: TimeInterval = 10
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
        
        // Wait for initial load
        try waitForAppReady()
    }
    
    private func waitForAppReady() throws {
        let headerTitle = app.staticTexts["Swiss News"]
        XCTAssertTrue(headerTitle.waitForExistence(timeout: timeout), "App header should exist")
    }
    
    func testSettingsNavigation() async throws {
        // Wait for initial load
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Find settings button and scroll to it
        let settingsButton = app.buttons["settingsButton"]
        let list = app.collectionViews.firstMatch
        
        // Scroll to bottom
        await list.swipeUp(velocity: .slow)
        
        XCTAssertTrue(settingsButton.waitForExistence(timeout: timeout), "Settings button should exist")
        await settingsButton.tap()
        
        // Verify navigation
        let settingsTitle = app.navigationBars["Einstellungen"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: timeout), "Settings title should exist")
    }
    
    func testArticleInteraction() async throws {
        // Wait for content to load
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Find and tap first article
        let readButton = app.buttons["readButton"].firstMatch
        XCTAssertTrue(readButton.waitForExistence(timeout: timeout), "Read button should exist")
        await readButton.tap()
        
        // Verify article detail view
        let articleView = app.scrollViews["articleDetailView"]
        XCTAssertTrue(articleView.waitForExistence(timeout: timeout), "Article detail view should exist")
    }
    
    func testSettingsTimeFilter() async throws {
        // Wait for initial load
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Navigate to settings
        let settingsButton = app.buttons["settingsButton"]
        let list = app.collectionViews.firstMatch
        
        // Scroll to bottom
        await list.swipeUp(velocity: .slow)
        
        XCTAssertTrue(settingsButton.waitForExistence(timeout: timeout), "Settings button should exist")
        await settingsButton.tap()
        
        // Verify time filter exists
        let picker = app.pickers.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: timeout), "Time filter picker should exist")
        
        // Test picker interaction
        await picker.tap()
        await app.buttons["24 Stunden"].tap()
        
        // Verify navigation back works
        await app.navigationBars["Einstellungen"].buttons.firstMatch.tap()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
        try super.tearDownWithError()
    }
} 
