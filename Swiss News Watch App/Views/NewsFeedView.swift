import SwiftUI

struct NewsFeedView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    @ObservedObject var readArticlesManager: ReadArticlesManager
    
    private var categoriesByType: [String: [NewsCategory]] {
        Dictionary(grouping: relevantCategories) { category in
            if category.id.contains("news") {
                return "News"
            } else if category.id.contains("sport") {
                return "Sport"
            } else if category.id.contains("culture") {
                return "Kultur"
            } else if category.id.contains("knowledge") {
                return "Wissen"
            }
            return "Andere"
        }
    }
    
    private var relevantCategories: [NewsCategory] {
        NewsCategory.available.filter { category in
            settings.selectedSources.contains(category.sourceId) && 
            settings.selectedCategories.contains(category.id)
        }
    }
    
    var body: some View {
        ForEach(["News", "Sport", "Kultur", "Wissen"], id: \.self) { category in
            if let categories = categoriesByType[category], !categories.isEmpty {
                Section(header: Text(category)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, category == "News" ? -20 : -5)
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
