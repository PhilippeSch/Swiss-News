import Foundation
import Combine

@MainActor
class RSSFeedParser: ObservableObject {
    @Published var newsItems: [String: [NewsItem]] = [:]
    @Published private(set) var state: LoadingState = .idle
    @Published var loadingCategories: Set<String> = []
    @Published var settings: Settings
    @Published private(set) var isSettingsViewActive = false
    
    private var refreshTask: Task<Void, Never>?
    private var settingsObserver: AnyCancellable?
    
    init(settings: Settings) {
        self.settings = settings
        setupSettingsObserver()
    }
    
    private func setupSettingsObserver() {
        settingsObserver = settings.$cutoffHours
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if !self.isSettingsViewActive {
                    Task {
                        await self.fetchAllFeeds()
                    }
                }
            }
    }
    
    func fetchAllFeeds() async {
        state = LoadingState.loading(lastUpdate: state.lastUpdate)
        loadingCategories.removeAll()
        
        // Mark categories that should be fetched
        for category in NewsCategory.available {
            let shouldFetch = settings.selectedSources.contains(category.sourceId) && 
                            settings.selectedCategories.contains(category.id)
            if shouldFetch {
                loadingCategories.insert(category.id)
            }
        }
        
        // Sequential loading
        for category in NewsCategory.available {
            let shouldFetch = settings.selectedSources.contains(category.sourceId) && 
                            settings.selectedCategories.contains(category.id)
            
            if shouldFetch {
                do {
                    let items = try await fetchNews(from: category.feedURL)
                    newsItems[category.id] = items
                } catch let error as AppError {
                    state = LoadingState.error(error)
                    return
                } catch {
                    state = LoadingState.error(AppError.networkError(error.localizedDescription))
                    return
                }
                loadingCategories.remove(category.id)
            }
        }
        
        state = LoadingState.loaded(Date())
    }
    
    private func fetchNews(from urlString: String) async throws -> [NewsItem] {
        guard let url = URL(string: urlString) else {
            throw AppError.invalidURL(urlString)
        }
        
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
        return items.filter { $0.pubDate > cutoffDate }
    }
    
    func setSettingsViewActive(_ active: Bool) {
        isSettingsViewActive = active
        
        if !active {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await fetchAllFeeds()
                isSettingsViewActive = false
            }
        }
    }
    
    func reset() {
        newsItems.removeAll()
        state = LoadingState.idle
        loadingCategories.removeAll()
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    func resetState() {
        state = LoadingState.idle
    }
} 
