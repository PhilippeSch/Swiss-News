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
    private let urlSession: URLSession
    private let cache: NewsCacheStore?

    init(settings: Settings, urlSession: URLSession? = nil, cache: NewsCacheStore? = NewsCacheStore()) {
        self.settings = settings
        self.urlSession = urlSession ?? AppURLSession.default
        self.cache = cache
        setupSettingsObserver()
    }

    private func setupSettingsObserver() {
        settingsObserver = settings.$cutoffHours
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }

                if !self.isSettingsViewActive {
                    Task {
                        // A changed time filter must re-filter regardless of age.
                        await self.fetchAllFeeds(force: true)
                    }
                }
            }
    }

    /// Restores the last persisted articles so the first frame has content.
    /// Does nothing once a fetch has already produced results.
    func loadCachedContent() async {
        guard case .idle = state, let cache else { return }
        guard let snapshot = await cache.load(), !snapshot.itemsByCategory.isEmpty else { return }

        newsItems = snapshot.itemsByCategory
        state = .loaded(snapshot.savedAt)
    }
    
    /// How many feeds may be in flight at once. Enough to hide latency without
    /// opening a socket per category.
    private static let maxConcurrentFetches = 5

    private struct FeedResult: Sendable {
        let categoryId: String
        let items: [NewsItem]?
        let error: AppError?
    }

    /// - Parameter force: bypasses the freshness check. Pull-to-refresh and an
    ///   explicit retry always fetch; a wrist-raise does not.
    func fetchAllFeeds(force: Bool = false) async {
        if !force, let lastUpdate = state.lastUpdate,
           Date().timeIntervalSince(lastUpdate) < Constants.Network.cacheValidityDuration {
            return
        }

        state = .loading(lastUpdate: state.lastUpdate)

        let categories = NewsCategory.available.filter {
            settings.selectedSources.contains($0.sourceId) && settings.selectedCategories.contains($0.id)
        }
        loadingCategories = Set(categories.map(\.id))

        guard !categories.isEmpty else {
            state = .loaded(state.lastUpdate ?? Date())
            return
        }

        // Read main-actor state once, so the child tasks capture only Sendable values.
        let session = urlSession
        let cutoffHours = settings.cutoffHours

        var hasNewData = false
        var errorsByCategory: [String: AppError] = [:]

        // Bounded concurrency: start a window of fetches, then top it up as each
        // one lands, so total time approaches the slowest feed rather than the sum.
        await withTaskGroup(of: FeedResult.self) { group in
            var pending = categories.makeIterator()

            for _ in 0..<Self.maxConcurrentFetches {
                guard let category = pending.next() else { break }
                group.addTask { await Self.loadFeed(for: category, using: session, cutoffHours: cutoffHours) }
            }

            // This loop runs on the main actor, so results are applied as they
            // arrive and each category's spinner clears independently.
            while let result = await group.next() {
                if let items = result.items {
                    if newsItems[result.categoryId] != items {
                        newsItems[result.categoryId] = items
                        hasNewData = true
                    }
                } else if let error = result.error {
                    errorsByCategory[result.categoryId] = error
                }
                loadingCategories.remove(result.categoryId)

                if let category = pending.next() {
                    group.addTask { await Self.loadFeed(for: category, using: session, cutoffHours: cutoffHours) }
                }
            }
        }

        if let firstError = categories.compactMap({ errorsByCategory[$0.id] }).first {
            state = .error(firstError) // Show first error, in category order
        } else if hasNewData {
            state = .loaded(Date()) // Only update timestamp if we got new data
        } else {
            state = .loaded(state.lastUpdate ?? Date()) // Keep existing timestamp
        }

        await persistCache()
    }

    private func persistCache() async {
        guard let cache, !newsItems.isEmpty else { return }
        await cache.save(itemsByCategory: newsItems, savedAt: state.lastUpdate ?? Date())
    }

    /// Fetches and parses one feed. `nonisolated` on purpose: the network wait
    /// and the XML parse must stay off the main actor.
    private nonisolated static func loadFeed(
        for category: NewsCategory,
        using session: URLSession,
        cutoffHours: Double
    ) async -> FeedResult {
        do {
            let items = try await fetchNews(from: category.feedURL, using: session, cutoffHours: cutoffHours)
            return FeedResult(categoryId: category.id, items: items, error: nil)
        } catch let error as AppError {
            // Skip 406 errors (Not Acceptable) - server doesn't serve this feed
            if case .networkError(let details) = error, details.contains("406") {
                return FeedResult(categoryId: category.id, items: [], error: nil)
            }
            return FeedResult(categoryId: category.id, items: nil, error: error)
        } catch {
            return FeedResult(categoryId: category.id, items: nil, error: .networkError(error.localizedDescription))
        }
    }

    private nonisolated static func fetchNews(
        from urlString: String,
        using session: URLSession,
        cutoffHours: Double
    ) async throws -> [NewsItem] {
        guard let url = URL(string: urlString) else {
            throw AppError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (watchOS) SwissNewsApp/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/rss+xml, application/xml, text/xml, */*", forHTTPHeaderField: "Accept")
        request.timeoutInterval = Constants.Network.timeoutInterval

        let (data, response) = try await session.data(for: request)

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

        // If no items were parsed, that's an error
        if items.isEmpty {
            throw AppError.noData
        }

        // If no time filter, return all items
        if cutoffHours == 0 {
            return items
        }

        // Filter by date - return empty array if all items are filtered out (not an error)
        let cutoffDate = Calendar.current.date(byAdding: .hour, value: Int(-cutoffHours), to: Date()) ?? Date()
        return items.filter { $0.pubDate > cutoffDate }
    }
    
    func setSettingsViewActive(_ active: Bool) {
        isSettingsViewActive = active
        
        if !active {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                // Settings just closed, so honour whatever changed there.
                await fetchAllFeeds(force: true)
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

        if let cache {
            Task { await cache.clear() }
        }
    }
    
    func resetState() {
        state = LoadingState.idle
    }
} 
