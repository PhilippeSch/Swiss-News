import SwiftUI

struct CategoryRowView: View {
    let category: NewsCategory
    let newsItems: [NewsItem]
    @ObservedObject var readArticlesManager: ReadArticlesManager
    @ObservedObject var rssParser: RSSFeedParser
    @State private var unreadCount: Int = 0
    
    var body: some View {
        NavigationLink {
            NewsCategoryView(
                title: category.title,
                newsItems: newsItems,
                readArticlesManager: readArticlesManager
            )
        } label: {
            SectionHeaderView(
                title: category.title,
                count: unreadCount,
                sourceId: category.sourceId,
                rssParser: rssParser,
                categoryId: category.id
            )
        }
        .accessibilityIdentifier("categoryRow_\(category.id)")
        .onAppear {
            updateUnreadCount()
        }
        .onChange(of: readArticlesManager.readArticles) { _, _ in
            updateUnreadCount()
        }
        .onChange(of: newsItems) { _, _ in
            updateUnreadCount()
        }
        .onChange(of: rssParser.state.lastUpdate) { _, _ in
            updateUnreadCount()
        }
        .task {
            updateUnreadCount()
        }
    }
    
    private func updateUnreadCount() {
        Task { @MainActor in
            unreadCount = newsItems.filter { !readArticlesManager.isRead($0.link) }.count
        }
    }
}

struct SectionHeaderView: View {
    let title: String
    let count: Int
    let sourceId: String
    @ObservedObject var rssParser: RSSFeedParser
    let categoryId: String
    
    var body: some View {
        HStack {
            Image(NewsSource.available.first { $0.id == sourceId }?.logoName ?? "")
                .resizable()
                .scaledToFit()
                .frame(height: 16)
                .padding(.trailing, 4)
            
            Text(title)
            
            Spacer()
            
            ZStack(alignment: .trailing) {
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .opacity(rssParser.loadingCategories.contains(categoryId) ? 0 : 1)
                
                ProgressView()
                    .scaleEffect(0.7)
                    .opacity(rssParser.loadingCategories.contains(categoryId) ? 1 : 0)
            }
            .frame(width: 30, alignment: .trailing)
        }
    }
} 