import Foundation

struct NewsItem: Identifiable {
    let title: String
    let description: String
    let pubDate: Date
    let link: String
    let guid: String
    let imageUrl: URL?
    
    var id: String { guid }
    
    var cleanDescription: String {
        description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
} 