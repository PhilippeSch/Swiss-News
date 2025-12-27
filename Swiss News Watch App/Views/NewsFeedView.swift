import SwiftUI

struct NewsFeedView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    @ObservedObject var readArticlesManager: ReadArticlesManager
    
    private var categoriesByType: [String: [NewsCategory]] {
        Dictionary(grouping: relevantCategories) { category in
            if category.id.contains("news") {
                return String(localized: "News")
            } else if category.id.contains("sport") {
                return String(localized: "Sport")
            } else if category.id.contains("culture") {
                return String(localized: "Kultur")
            } else if category.id.contains("knowledge") {
                return String(localized: "Wissen")
            }
            return String(localized: "Andere")
        }
    }
    
    private var relevantCategories: [NewsCategory] {
        NewsCategory.available.filter { category in
            settings.selectedSources.contains(category.sourceId) && 
            settings.selectedCategories.contains(category.id)
        }
    }
    
    var body: some View {
        ForEach([String(localized: "News"), String(localized: "Sport"), String(localized: "Kultur"), String(localized: "Wissen")], id: \.self) { category in
            if let categories = categoriesByType[category], !categories.isEmpty {
                Section(header: Text(category)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, category == String(localized: "News") ? -20 : -5)
                ) {
                    ForEach(categories) { category in
                        CategoryRowView(
                            category: category,
                            newsItems: rssParser.newsItems[category.id] ?? [],
                            readArticlesManager: readArticlesManager,
                            rssParser: rssParser
                        )
                    }
                }
            }
        }
    }
} 
