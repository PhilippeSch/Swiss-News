import Foundation

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
    
    @Published var generalNews: [NewsItem] = []
    @Published var internationalNews: [NewsItem] = []
    @Published var economyNews: [NewsItem] = []
    @Published var scienceNews: [NewsItem] = []
    @Published var sportNews: [NewsItem] = []
    @Published var cultureNews: [NewsItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdate: Date?
    
    private let generalFeedURL = "https://www.srf.ch/news/bnf/rss/19032223"
    private let internationalFeedURL = "https://www.srf.ch/news/bnf/rss/1922"
    private let economyFeedURL = "https://www.srf.ch/news/bnf/rss/1926"
    private let scienceFeedURL = "https://www.srf.ch/bnf/rss/630"
    private let sportFeedURL = "https://www.srf.ch/sport/bnf/rss/718"
    private let cultureFeedURL = "https://www.srf.ch/kultur/bnf/rss/454"
    
    private let cache = NSCache<NSString, NSArray>()
    
    private func saveToCache(_ items: [NewsItem], for key: String) {
        cache.setObject(items as NSArray, forKey: key as NSString)
    }
    
    private func loadFromCache(for key: String) -> [NewsItem]? {
        return cache.object(forKey: key as NSString) as? [NewsItem]
    }
    
    func fetchAllFeeds() async {
        // Try loading from cache first
        if let cached = loadFromCache(for: "generalNews") {
            self.generalNews = cached
        }
        
        self.isLoading = true
        self.error = nil
        
        do {
            async let general = fetchNews(from: generalFeedURL)
            async let international = fetchNews(from: internationalFeedURL)
            async let economy = fetchNews(from: economyFeedURL)
            async let science = fetchNews(from: scienceFeedURL)
            async let sport = fetchNews(from: sportFeedURL)
            async let culture = fetchNews(from: cultureFeedURL)
            
            let (generalItems, internationalItems, economyItems, 
                 scienceItems, sportItems, cultureItems) = await (
                general, international, economy, 
                science, sport, culture
            )
            
            // Sort items by date
            self.generalNews = generalItems.sorted { $0.pubDate > $1.pubDate }
            self.internationalNews = internationalItems.sorted { $0.pubDate > $1.pubDate }
            self.economyNews = economyItems.sorted { $0.pubDate > $1.pubDate }
            self.scienceNews = scienceItems.sorted { $0.pubDate > $1.pubDate }
            self.sportNews = sportItems.sorted { $0.pubDate > $1.pubDate }
            self.cultureNews = cultureItems.sorted { $0.pubDate > $1.pubDate }
            self.isLoading = false
            
            self.lastUpdate = Date()
            
            // Save to cached
            saveToCache(self.generalNews, for: "generalNews")
        } catch {
            self.error = error
            self.isLoading = false
        }
    }
    
    private func fetchNews(from urlString: String) async -> [NewsItem] {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parser = XMLParser(data: data)
            let delegate = RSSParserDelegate()
            parser.delegate = delegate
            
            if parser.parse() {
                return delegate.newsItems
            } else if let error = parser.parserError {
                print("Parser error: \(error.localizedDescription)")
            }
        } catch {
            print("Network error: \(error.localizedDescription)")
        }
        return []
    }
}

final class RSSParserDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentLink = ""
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
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if parsingItem {
            switch currentElement {
            case "title": currentTitle += string
            case "description": currentDescription += string
            case "pubDate": currentPubDate += string
            case "link": currentLink += string
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
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            newsItems.append(newsItem)
            parsingItem = false
        }
    }
} 
