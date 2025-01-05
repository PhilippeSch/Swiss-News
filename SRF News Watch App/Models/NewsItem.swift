import Foundation

struct NewsItem: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let title: String
    let description: String
    let pubDate: Date
    let link: String
    let guid: String
    
    var isRead: Bool = false
    
    init(title: String, description: String, pubDate: Date, link: String, guid: String) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.pubDate = pubDate
        self.link = link
        self.guid = guid
    }
    
    // Convert string URL to URL type for better handling
    var imageUrl: URL? {
        // Extract image URL from description if it exists
        if let range = description.range(of: "src=\"(.*?)\"", options: .regularExpression) {
            let urlString = String(description[range]).replacingOccurrences(of: "src=\"", with: "").dropLast()
            return URL(string: String(urlString))
        }
        return nil
    }
    
    // Clean description by removing HTML tags
    var cleanDescription: String {
        description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    var dayGroup: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: pubDate)
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
        lhs.id == rhs.id
    }
} 