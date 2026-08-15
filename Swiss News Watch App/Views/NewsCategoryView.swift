import SwiftUI

struct NewsCategoryView: View {
    let title: String
    let newsItems: [NewsItem]
    @ObservedObject var readArticlesManager: ReadArticlesManager
    @State private var isViewingArticle = false
    @State private var viewedArticles: Set<String> = []
    
    var body: some View {
        ScrollView {
            if newsItems.isEmpty {
                EmptyStateView()
            } else {
                ArticleListView(
                    newsItems: newsItems,
                    readArticlesManager: readArticlesManager,
                    isViewingArticle: $isViewingArticle,
                    viewedArticles: $viewedArticles
                )
                .accessibilityIdentifier("articleList")
            }
        }
        .navigationTitle(title)
        .accessibilityIdentifier("newsCategoryView")
        .onAppear {
            isViewingArticle = false
            viewedArticles.removeAll()
        }
        .onDisappear {
            // Only mark articles as read when leaving the view if not going to read an article
            if !isViewingArticle {
                for articleUrl in viewedArticles {
                    readArticlesManager.markAsViewed(articleUrl)
                }
            }
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
    @Binding var isViewingArticle: Bool
    @Binding var viewedArticles: Set<String>
    
    var body: some View {
        LazyVStack(spacing: 12) {
            ForEach(newsItems) { item in
                ArticleRowView(
                    item: item,
                    readArticlesManager: readArticlesManager,
                    isViewingArticle: $isViewingArticle
                )
                .accessibilityIdentifier("articleRow_\(item.guid)")
                .onAppear {
                    viewedArticles.insert(item.link)
                }
            }
        }
        .padding(.vertical)
        .accessibilityIdentifier("articleListContent")
    }
}

private struct ArticleRowView: View {
    let item: NewsItem
    @ObservedObject var readArticlesManager: ReadArticlesManager
    @Binding var isViewingArticle: Bool
    
    /// Shared across rows — a stored property would allocate a formatter every
    /// time the row struct is rebuilt during scrolling.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
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
                Text(Self.dateFormatter.string(from: item.pubDate))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                ReadButton(
                    title: item.title,
                    url: item.link,
                    readArticlesManager: readArticlesManager,
                    isViewingArticle: $isViewingArticle
                )
            }
        }
        .padding()
        .background(Color(white: 0.3, opacity: 0.4))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

/// Replaces AsyncImage, which downloads full-resolution press photos and does
/// not keep decoded images across view reloads, so images re-download on scroll.
private struct ArticleImageView: View {
    let imageUrl: URL

    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        content
            .task(id: imageUrl) {
                await load()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else if didFail {
            Image(systemName: "photo")
                .imageScale(.large)
                .foregroundColor(.gray)
        } else {
            ProgressView()
        }
    }

    private func load() async {
        let key = ArticleImageLoader.cacheKey(for: imageUrl)

        if let cached = ImageCache.shared.image(forKey: key) {
            image = cached
            return
        }

        do {
            let loaded = try await ArticleImageLoader.load(imageUrl)
            guard !Task.isCancelled else { return }
            ImageCache.shared.insert(loaded, forKey: key)
            image = loaded
        } catch {
            guard !Task.isCancelled else { return }
            didFail = true
        }
    }
}

private struct ReadButton: View {
    let title: String
    let url: String
    @ObservedObject var readArticlesManager: ReadArticlesManager
    @Binding var isViewingArticle: Bool
    @State private var isNavigationActive = false
    
    var body: some View {
        NavigationLink {
            ArticleView(
                title: title,
                url: url,
                isPresented: $isNavigationActive
            )
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
        // On the link itself, not its label, so it is exposed as a button.
        .accessibilityIdentifier("readButton")
        .simultaneousGesture(TapGesture().onEnded {
            isViewingArticle = true
            readArticlesManager.markAsViewed(url)
        })
    }
}

#Preview {
    NavigationStack {
        NewsCategoryView(
            title: "News",
            newsItems: [
                NewsItem(
                    title: "Bundesrat beschliesst neue Massnahmen",
                    description: "Die Landesregierung hat an ihrer Sitzung weitreichende Entscheide gefällt und informiert die Öffentlichkeit.",
                    pubDate: Date().addingTimeInterval(-3600),
                    link: "https://example.com/1",
                    guid: "preview-1"
                ),
                NewsItem(
                    title: "SCB gewinnt das Spitzenspiel",
                    description: "In einer umkämpften Partie setzte sich der SC Bern im Penaltyschiessen durch.",
                    pubDate: Date().addingTimeInterval(-7200),
                    link: "https://example.com/2",
                    guid: "preview-2"
                )
            ],
            readArticlesManager: ReadArticlesManager()
        )
    }
}
