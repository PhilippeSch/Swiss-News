import Foundation

class ReadArticlesManager: ObservableObject {
    @Published private(set) var readArticles: Set<String>
    @Published private var viewedArticles: Set<String>
    private let defaults = UserDefaults.standard
    private let readArticlesKey = Constants.UserDefaults.readArticlesKey
    
    init() {
        if let data = defaults.data(forKey: readArticlesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            readArticles = decoded
        } else {
            readArticles = []
        }
        viewedArticles = []
    }
    
    func markAsViewed(_ articleLink: String) {
        viewedArticles.insert(articleLink)
    }
    
    func markAllViewedAsRead() {
        readArticles.formUnion(viewedArticles)
        viewedArticles.removeAll()
        saveReadArticles()
    }
    
    func isRead(_ articleLink: String) -> Bool {
        readArticles.contains(articleLink)
    }
    
    private func saveReadArticles() {
        if let encoded = try? JSONEncoder().encode(readArticles) {
            defaults.set(encoded, forKey: readArticlesKey)
        }
    }
} 