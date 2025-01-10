import Foundation
import Combine

@MainActor
class RSSFeedParser: ObservableObject {
    @Published var newsItems: [String: [NewsItem]] = [:]
    @Published private(set) var state: LoadingState = .idle
    @Published var loadingCategories: Set<String> = []
    @Published var settings: Settings
    
    private var settingsObserver: AnyCancellable?
    private var refreshTask: Task<Void, Never>?
    private var isSettingsViewActive = false
    
    // Neuer State Manager
    private enum RefreshState {
        case idle
        case refreshing
        case pendingRefresh
    }
    private var currentState: RefreshState = .idle
    
    init(settings: Settings) {
        self.settings = settings
        setupSettingsObserver()
    }
    
    private func setupSettingsObserver() {
        settingsObserver = settings.$selectedCategories
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] categories in
                guard let self = self else { return }
                print("🔄 Categories changed in RSSFeedParser")
                print("Current categories: \(categories)")
                
                if self.isSettingsViewActive {
                    print("⏳ Settings view active, will refresh after closing")
                    self.currentState = .pendingRefresh
                    return
                }
                
                Task {
                    await self.tryRefresh()
                }
            }
    }
    
    private func tryRefresh() async {
        switch currentState {
        case .idle:
            await startRefresh()
        case .refreshing:
            print("⏳ Refresh already in progress, marking as pending")
            currentState = .pendingRefresh
        case .pendingRefresh:
            print("⏳ Refresh already pending")
        }
    }
    
    private func startRefresh() async {
        print("🔄 Starting refresh")
        currentState = .refreshing
        refreshTask?.cancel()
        
        refreshTask = Task {
            print("📡 Fetching feeds...")
            await fetchAllFeeds()
            
            if currentState == .pendingRefresh {
                print("🔄 Executing pending refresh")
                currentState = .idle
                await tryRefresh()
            } else {
                currentState = .idle
            }
        }
    }
    
    func setSettingsViewActive(_ active: Bool) {
        print("🔧 Settings view active state changed to: \(active)")
        isSettingsViewActive = active
        
        if !active && currentState == .pendingRefresh {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                print("🔄 Settings view closed, executing pending refresh")
                await tryRefresh()
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
    
    func reset() {
        newsItems.removeAll()
        loadingCategories.removeAll()
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
    private var currentMediaThumbnail = ""
    private var parsingItem = false
    
    var newsItems: [NewsItem] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "item" {
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentGuid = ""
            currentEnclosureUrl = ""
            currentMediaThumbnail = ""
            parsingItem = true
        } else if elementName == "enclosure" {
            currentEnclosureUrl = attributeDict["url"] ?? ""
        } else if elementName == "media:thumbnail" {
            currentMediaThumbnail = attributeDict["url"] ?? ""
        }
        currentElement = elementName
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
            
            if !currentMediaThumbnail.isEmpty {
                finalDescription += "<enclosure url=\"\(currentMediaThumbnail)\" type=\"image/jpeg\"/>"
            } else if !currentEnclosureUrl.isEmpty {
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
