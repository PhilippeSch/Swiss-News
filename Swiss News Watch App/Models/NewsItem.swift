import Foundation

struct NewsItem: Identifiable, Equatable {
    let title: String
    let description: String
    let pubDate: Date
    let link: String
    let guid: String
    
    var id: String { guid }
    
    var cleanDescription: String {
        description
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var imageUrl: URL? {
        let pattern = "<enclosure url=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: description, range: NSRange(description.startIndex..., in: description)),
              let range = Range(match.range(at: 1), in: description) else {
            return nil
        }
        return URL(string: String(description[range]))
    }
    
    static func == (lhs: NewsItem, rhs: NewsItem) -> Bool {
        lhs.guid == rhs.guid &&
        lhs.title == rhs.title &&
        lhs.description == rhs.description &&
        lhs.pubDate == rhs.pubDate
    }
} 