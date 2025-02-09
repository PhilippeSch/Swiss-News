import XCTest
@testable import Swiss_News_Watch_App

final class ReadArticlesManagerTests: XCTestCase {
    var manager: ReadArticlesManager!
    let testUrl1 = "https://test.com/article1"
    let testUrl2 = "https://test.com/article2"
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        manager = ReadArticlesManager()
    }
    
    func testMarkAsViewed() {
        XCTAssertFalse(manager.isRead(testUrl1))
        
        manager.markAsViewed(testUrl1)
        XCTAssertTrue(manager.isRead(testUrl1))
    }
    
    func testMultipleArticles() {
        XCTAssertFalse(manager.isRead(testUrl1))
        XCTAssertFalse(manager.isRead(testUrl2))
        
        manager.markAsViewed(testUrl1)
        XCTAssertTrue(manager.isRead(testUrl1))
        XCTAssertFalse(manager.isRead(testUrl2))
        
        manager.markAsViewed(testUrl2)
        XCTAssertTrue(manager.isRead(testUrl1))
        XCTAssertTrue(manager.isRead(testUrl2))
    }
    
    func testPersistence() {
        manager.markAsViewed(testUrl1)
        
        // Create new instance to test persistence
        let newManager = ReadArticlesManager()
        XCTAssertTrue(newManager.isRead(testUrl1))
    }
} 
