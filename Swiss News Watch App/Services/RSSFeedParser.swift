import Foundation
import Combine

@MainActor
class RSSFeedParser: ObservableObject {
    @Published var newsItems: [String: [NewsItem]] = [:]
    @Published private(set) var state: LoadingState = .idle
    @Published var loadingCategories: Set<String> = []
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
        if case .loaded(let date) = state {
            state = .loading(lastUpdate: date)
        } else {
            state = .loading(lastUpdate: nil)
        }
        
        // Zuerst alle zu ladenden Kategorien markieren
        for category in NewsCategory.available {
            let shouldFetch = settings.selectedSources.contains(category.sourceId) && 
                            settings.selectedCategories.contains(category.id)
            if shouldFetch {
                loadingCategories.insert(category.id)
            }
        }
        
        // Dann sequentiell laden
        for category in NewsCategory.available {
            let shouldFetch = settings.selectedSources.contains(category.sourceId) && 
                            settings.selectedCategories.contains(category.id)
            
            if shouldFetch {
                do {
                    let items = try await fetchNews(from: category.feedURL)
                    newsItems[category.id] = items
                } catch {
                    print("Error fetching \(category.title): \(error.localizedDescription)")
                }
                loadingCategories.remove(category.id)
            }
        }
        
        state = .loaded(Date())
    }
    
    private func fetchNews(from urlString: String) async throws -> [NewsItem] {
        guard let url = URL(string: urlString) else {
            throw AppError.invalidURL(urlString)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.networkError("Invalid response")
            }
            
            guard httpResponse.statusCode == 200 else {
                throw AppError.networkError("Server returned \(httpResponse.statusCode)")
            }
            
            let parser = XMLParser(data: data)
            let delegate = RSSParserDelegate()
            parser.delegate = delegate
            
            guard parser.parse() else {
                if let error = parser.parserError {
                    throw AppError.parsingError(error.localizedDescription)
                }
                throw AppError.parsingError("Unknown parsing error")
            }
            
            let items = delegate.newsItems
            
            if items.isEmpty {
                throw AppError.noData
            }
            
            if settings.cutoffHours == 0 {
                return items
            }
            
            let cutoffDate = Calendar.current.date(byAdding: .hour, value: Int(-settings.cutoffHours), to: Date()) ?? Date()
            let filteredItems = items.filter { $0.pubDate > cutoffDate }
            
            return filteredItems
            
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.networkError(error.localizedDescription)
        }
    }
    
    func resetState() {
        state = .idle
    }
}

final class RSSParserDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentLink = ""
    private var currentGuid = ""
    private var currentEnclosureUrl = ""
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
            currentEnclosureUrl = ""
        } else if elementName == "enclosure" {
            if let url = attributeDict["url"] {
                currentEnclosureUrl = url
            }
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
            
            var finalDescription = currentDescription
            if !currentEnclosureUrl.isEmpty {
                finalDescription += "<enclosure url=\"\(currentEnclosureUrl)\" type=\"image/jpeg\"/>"
            }
            
            let newsItem = NewsItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: finalDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: pubDate,
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                guid: currentGuid.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            newsItems.append(newsItem)
            parsingItem = false
        }
    }
} 
