import SwiftUI
import WatchKit

struct NewsCategoryView: View {
    let title: String
    let newsItems: [NewsItem]
    @ObservedObject var readArticlesManager: ReadArticlesManager
    
    var body: some View {
        ScrollView {
            if newsItems.isEmpty {
                EmptyStateView()
            } else {
                ArticleListView(
                    newsItems: newsItems,
                    readArticlesManager: readArticlesManager
                )
            }
        }
        .navigationTitle(title)
        .onDisappear {
            readArticlesManager.markAllViewedAsRead()
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Aktuell keine Artikel verfügbar")
                .font(.headline)
                .foregroundColor(.gray)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct ArticleListView: View {
    let newsItems: [NewsItem]
    @ObservedObject var readArticlesManager: ReadArticlesManager
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(newsItems) { item in
                ArticleRowView(
                    item: item,
                    readArticlesManager: readArticlesManager
                )
            }
        }
        .padding(.vertical)
    }
}

private struct ArticleRowView: View {
    let item: NewsItem
    @ObservedObject var readArticlesManager: ReadArticlesManager
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.dateFormat = "dd.MM.yy\nHH:mm"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(readArticlesManager.isRead(item.link) ? Constants.UI.readArticleOpacity : 1)
            
            if let imageUrl = item.imageUrl {
                ArticleImageView(imageUrl: imageUrl)
            }
            
            Text(item.cleanDescription)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(nil)
                .opacity(readArticlesManager.isRead(item.link) ? Constants.UI.readArticleOpacity : 1)
            
            HStack {
                Text(dateFormatter.string(from: item.pubDate))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                ReadButton(
                    title: item.title,
                    url: item.link,
                    readArticlesManager: readArticlesManager
                )
            }
        }
        .padding()
        .background(Color(white: 0.3, opacity: 0.4))
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            readArticlesManager.markAsViewed(item.link)
        }
    }
}

private struct ArticleImageView: View {
    let imageUrl: URL
    
    var body: some View {
        AsyncImage(url: imageUrl) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            case .failure(_):
                Image(systemName: "photo")
                    .imageScale(.large)
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }
}

private struct ReadButton: View {
    let title: String
    let url: String
    @ObservedObject var readArticlesManager: ReadArticlesManager
    
    var body: some View {
        NavigationLink {
            ArticleView(title: title, url: url)
                .onAppear {
                    readArticlesManager.markAsViewed(url)
                }
        } label: {
            Text("Lesen")
                .font(.system(size: 14))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
} 
