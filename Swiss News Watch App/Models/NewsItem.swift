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
        // First try to extract image URL from enclosure tag
        if let enclosureStart = description.range(of: "<enclosure"),
           let urlStart = description[enclosureStart.upperBound...].range(of: "url=\""),
           let urlEnd = description[urlStart.upperBound...].range(of: "\"") {
            let urlString = String(description[urlStart.upperBound..<urlEnd.lowerBound])
            return URL(string: urlString)
        }
        
        // If no enclosure, try the SRF style with src attribute
        if let srcStart = description.range(of: "src=\""),
           let srcEnd = description[srcStart.upperBound...].range(of: "\"") {
            let urlString = String(description[srcStart.upperBound..<srcEnd.lowerBound])
            return URL(string: urlString)
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