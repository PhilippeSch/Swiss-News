import SwiftUI

enum Constants {
    enum UI {
        static let cornerRadius: CGFloat = 8
        static let defaultPadding: CGFloat = 16
        static let minimumScale: CGFloat = 0.8
        static let readArticleOpacity: CGFloat = 0.6
    }
    
    enum Network {
        static let timeoutInterval: TimeInterval = 30
        static let cacheValidityDuration: TimeInterval = 300
    }
    
    enum UserDefaults {
        static let firstLaunchKey = "com.scheuber.swissnews.firstLaunch"
        static let selectedCategoriesKey = "selectedCategories"
        static let categoryOrderKey = "categoryOrder"
        static let cutoffHoursKey = "cutoffHours"
        static let readArticlesKey = "com.scheuber.swissnews.readArticles"
    }
} 