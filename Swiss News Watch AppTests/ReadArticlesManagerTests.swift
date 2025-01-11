import XCTest
@testable import Swiss_News_Watch_App

final class ReadArticlesManagerTests: XCTestCase {
    var manager: ReadArticlesManager!
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.readArticlesKey)
        manager = ReadArticlesManager()
    }
    
    func testArticleReadStateManagement() {
        let articleLink = "https://nzz.ch/article"
        
        // Initially, article should not be marked as read
        XCTAssertFalse(manager.isRead(articleLink), "New article should not be marked as read")
        
        // Mark article as viewed
        manager.markAsViewed(articleLink)
        
        // Article should still not be read until markAllViewedAsRead is called
        XCTAssertFalse(manager.isRead(articleLink), "Viewed article should not be marked as read until markAllViewedAsRead is called")
        
        // Mark all viewed articles as read
        manager.markAllViewedAsRead()
        
        // Now the article should be marked as read
        XCTAssertTrue(manager.isRead(articleLink), "Article should be marked as read after markAllViewedAsRead")
    }
    
    func testPersistence() {
        let articleLink = "https://test.com/article"
        
        // Mark article as read
        manager.markAsViewed(articleLink)
        manager.markAllViewedAsRead()
        
        // Create new manager instance to test persistence
        let newManager = ReadArticlesManager()
        
        // Article should still be marked as read
        XCTAssertTrue(newManager.isRead(articleLink))
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.readArticlesKey)
        manager = nil
        super.tearDown()
    }
} 
