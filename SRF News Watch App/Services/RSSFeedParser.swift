import Foundation
import Combine

@MainActor
class RSSFeedParser: ObservableObject {
    enum FeedError: LocalizedError, Sendable {
        case fetchError(String)
        case parseError(String)
        
        var errorDescription: String? {
            switch self {
            case .fetchError(let message): return "Fehler beim Laden: \(message)"
            case .parseError(let message): return "Fehler beim Verarbeiten: \(message)"
            }
        }
    }
    
    @Published var newsItems: [String: [NewsItem]] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdate: Date?
    @Published var settings: Settings
    
    private var settingsObserver: AnyCancellable?
    
    init(settings: Settings) {
        self.settings = settings
        settingsObserver = settings.$selectedCategories.sink { [weak self] _ in
            Task {
                await self?.fetchAllFeeds()
            }
        }
    }
    
    func fetchAllFeeds() async {
        print("Starting fetch...")
        self.isLoading = true
        self.error = nil
        
        do {
            var feeds: [String: [NewsItem]] = [:]
            
            // Only fetch selected categories
            for category in NewsCategory.available where settings.selectedCategories.contains(category.id) {
                feeds[category.id] = try await fetchNews(from: category.feedURL)
            }
            
            self.newsItems = feeds
            self.lastUpdate = Date()
            
        } catch {
            print("Fetch error: \(error.localizedDescription)")
            self.error = error
        }
        
        self.isLoading = false
    }
    
    private func fetchNews(from urlString: String) async throws -> [NewsItem] {
        guard let url = URL(string: urlString) else {
            throw FeedError.fetchError("Invalid URL: \(urlString)")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parser = XMLParser(data: data)
            let delegate = RSSParserDelegate()
            parser.delegate = delegate
            
            if parser.parse() {
                // If cutoffHours is 0, return all articles
                if settings.cutoffHours == 0 {
                    return delegate.newsItems
                }
                let cutoffDate = Calendar.current.date(byAdding: .hour, value: Int(-settings.cutoffHours), to: Date()) ?? Date()
                return delegate.newsItems.filter { $0.pubDate > cutoffDate }
            } else if let error = parser.parserError {
                throw FeedError.parseError(error.localizedDescription)
            }
            throw FeedError.parseError("Unknown parsing error")
        } catch {
            throw FeedError.fetchError(error.localizedDescription)
        }
    }
}

final class RSSParserDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentLink = ""
    private var currentGuid = ""
    private var parsingItem = false
    
    var newsItems: [NewsItem] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            parsingItem = true
            currentTitle = ""
            currentDescription = ""
            currentPubDate = ""
            currentLink = ""
            currentGuid = ""
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if parsingItem {
            switch currentElement {
            case "title": currentTitle += string
            case "description": currentDescription += string
            case "pubDate": currentPubDate += string
            case "link": currentLink += string
            case "guid": currentGuid += string
            default: break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            
            let pubDate = dateFormatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Date()
            
            let newsItem = NewsItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: pubDate,
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                guid: currentGuid.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            newsItems.append(newsItem)
            parsingItem = false
        }
    }
} 
