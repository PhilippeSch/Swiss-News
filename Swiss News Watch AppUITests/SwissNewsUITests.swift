import XCTest

/// End-to-end coverage of the main flows, driven against canned feeds
/// (`-UITesting`) so runs do not depend on the network or on live headlines.
final class SwissNewsUITests: XCTestCase {
    private var app: XCUIApplication!
    private let timeout: TimeInterval = 20

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [UITestLaunch.argument]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Launch

    func testHomeScreenShowsHeaderAndCategories() throws {
        XCTAssertTrue(app.staticTexts["Swiss News"].waitForExistence(timeout: timeout), "Header should appear")

        let firstCategory = categoryRow("srf_news_all")
        XCTAssertTrue(firstCategory.waitForExistence(timeout: timeout), "Seeded categories should be listed")
    }

    func testWelcomeScreenIsSkippedForASeededInstall() throws {
        XCTAssertTrue(app.staticTexts["Swiss News"].waitForExistence(timeout: timeout))
        XCTAssertFalse(
            app.staticTexts["Willkommen bei Swiss News 👋"].exists,
            "A seeded install should go straight to the feed"
        )
    }

    func testEverySeededCategoryEventuallyLoads() throws {
        let firstCategory = categoryRow("srf_news_all")
        XCTAssertTrue(firstCategory.waitForExistence(timeout: timeout))

        // Spinners clear as each feed lands; the unread count replaces them.
        let expectedCount = "\(UITestLaunch.articlesPerCategory)"
        XCTAssertTrue(
            app.staticTexts[expectedCount].waitForExistence(timeout: timeout),
            "A category should end up showing its unread count"
        )
    }

    // MARK: - Category and article flow

    func testOpeningACategoryShowsItsArticles() throws {
        let category = categoryRow("srf_news_all")
        XCTAssertTrue(category.waitForExistence(timeout: timeout))
        category.tap()

        let list = app.otherElements["articleList"]
        XCTAssertTrue(list.waitForExistence(timeout: timeout), "Article list should appear")
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Testartikel'")).firstMatch
                .waitForExistence(timeout: timeout),
            "Stubbed articles should be rendered"
        )
    }

    func testReadingAnArticleOpensTheDetailView() throws {
        openFirstCategory()

        let readButton = firstReadButton()
        readButton.tap()

        XCTAssertTrue(
            app.scrollViews["articleDetailView"].waitForExistence(timeout: timeout),
            "Article detail view should open"
        )
    }

    func testReadArticleIsMarkedAsReadOnReturn() throws {
        openFirstCategory()

        firstReadButton().tap()
        XCTAssertTrue(app.scrollViews["articleDetailView"].waitForExistence(timeout: timeout))

        goBack()
        XCTAssertTrue(app.otherElements["articleList"].waitForExistence(timeout: timeout))

        goBack()
        // One article of the four was read, so the badge should drop by one.
        let remaining = "\(UITestLaunch.articlesPerCategory - 1)"
        XCTAssertTrue(
            app.staticTexts[remaining].waitForExistence(timeout: timeout),
            "Unread count should drop after reading an article"
        )
    }

    // MARK: - Scroll restoration (issue #18)

    func testReturningFromALowerCategoryKeepsItOnScreen() throws {
        let lastCategoryId = UITestLaunch.lastCategoryId
        let lastCategory = categoryRow(lastCategoryId)

        XCTAssertTrue(categoryRow("srf_news_all").waitForExistence(timeout: timeout))

        // Reach a category in the lower part of the home screen.
        var attempts = 0
        while !lastCategory.isHittable && attempts < 8 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(lastCategory.isHittable, "Should be able to reach the lower category")

        lastCategory.tap()
        XCTAssertTrue(app.otherElements["articleList"].waitForExistence(timeout: timeout))

        goBack()

        XCTAssertTrue(lastCategory.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            lastCategory.isHittable,
            "Returning should land back at the category, not at the top of the list"
        )
    }

    // MARK: - Settings

    func testSettingsOpensAndClosesAgain() throws {
        openSettings()
        goBack()

        // Reaching settings scrolls to the bottom, so the header is not
        // rendered until the list is scrolled back up.
        var attempts = 0
        while !app.staticTexts["Swiss News"].exists && attempts < 8 {
            app.swipeDown()
            attempts += 1
        }

        XCTAssertTrue(
            app.staticTexts["Swiss News"].waitForExistence(timeout: timeout),
            "Should return to the home screen"
        )
    }

    func testTimeFilterIsPresentInSettings() throws {
        openSettings()

        XCTAssertTrue(
            app.staticTexts["Zeitraum"].waitForExistence(timeout: timeout),
            "Time filter should be offered in settings"
        )
    }

    func testSourceSelectionOpensFromSettings() throws {
        openSettings()

        let sourcesButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Quellen'")
        ).firstMatch
        XCTAssertTrue(sourcesButton.waitForExistence(timeout: timeout), "Source selection should be reachable")
        sourcesButton.tap()

        XCTAssertTrue(
            app.staticTexts["Willkommen bei Swiss News 👋"].waitForExistence(timeout: timeout),
            "Source selection screen should open"
        )
    }

    // MARK: - Refresh

    func testPullToRefreshKeepsContentOnScreen() throws {
        let category = categoryRow("srf_news_all")
        XCTAssertTrue(category.waitForExistence(timeout: timeout))

        app.swipeDown()

        XCTAssertTrue(
            category.waitForExistence(timeout: timeout),
            "Content should survive a refresh"
        )
    }

    // MARK: - Helpers

    private func categoryRow(_ id: String) -> XCUIElement {
        app.buttons["categoryRow_\(id)"]
    }

    private func openFirstCategory() {
        let category = categoryRow("srf_news_all")
        XCTAssertTrue(category.waitForExistence(timeout: timeout), "First category should exist")
        category.tap()
    }

    /// SwiftUI exposes these rows as plain `Other` elements on watchOS rather
    /// than buttons, so match on identifier across any element type. The row's
    /// title and image also fill the screen, so scroll until it shows up.
    @discardableResult
    private func firstReadButton() -> XCUIElement {
        XCTAssertTrue(app.otherElements["articleList"].waitForExistence(timeout: timeout), "Articles should load")

        let readButton = app.descendants(matching: .any).matching(identifier: "readButton").firstMatch

        var attempts = 0
        while !readButton.exists && attempts < 8 {
            app.swipeUp()
            attempts += 1
        }

        XCTAssertTrue(readButton.waitForExistence(timeout: timeout), "Read button should be reachable")
        return readButton
    }

    private func openSettings() {
        let settingsButton = app.buttons["settingsButton"]

        var attempts = 0
        while !settingsButton.exists && attempts < 8 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(settingsButton.waitForExistence(timeout: timeout), "Settings button should be reachable")
        settingsButton.tap()

        XCTAssertTrue(
            app.staticTexts["Artikel Filter"].waitForExistence(timeout: timeout),
            "Settings screen should open"
        )
    }

    private func goBack() {
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: timeout) {
            backButton.tap()
        } else {
            app.swipeRight()
        }
    }
}

/// Mirrors the app-side UITestSupport values; the app target is not importable
/// from the UI test bundle.
enum UITestLaunch {
    static let argument = "-UITesting"
    static let articlesPerCategory = 4
    static let lastCategoryId = "srf_knowledge_all"
}
