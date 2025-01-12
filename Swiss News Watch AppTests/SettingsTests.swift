import XCTest
@testable import Swiss_News_Watch_App

final class SettingsTests: XCTestCase {
    var settings: Settings!
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.cutoffHoursKey)
        settings = Settings()
    }
    
    func testTimeFilterDefaults() {
        XCTAssertEqual(settings.cutoffHours, 48.0, "Default cutoff should be 48 hours")
    }
    
    func testTimeFilterPersistence() {
        // Change time filter
        settings.cutoffHours = 24.0
        
        // Create new settings instance to test persistence
        let newSettings = Settings()
        XCTAssertEqual(newSettings.cutoffHours, 24.0, "Time filter setting should persist")
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaults.cutoffHoursKey)
        settings = nil
        super.tearDown()
    }
} 