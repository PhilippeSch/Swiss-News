//
//  ContentView.swift
//  Swiss News Watch App
//
//  Created by Philippe Scheuber on 31.12.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings: Settings
    @StateObject private var rssParser: RSSFeedParser
    @StateObject private var readArticlesManager = ReadArticlesManager()
    @State private var currentTime = Date()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isRefreshing = false
    @State private var showWelcome = false
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init() {
        print("ContentView init")
        let settings = Settings()
        print("Initial isFirstLaunch value: \(settings.isFirstLaunch)")
        _settings = StateObject(wrappedValue: settings)
        _rssParser = StateObject(wrappedValue: RSSFeedParser(settings: settings))
        _showWelcome = State(initialValue: settings.isFirstLaunch)
    }
    
    var body: some View {
        NavigationView {
            List {
                if !settings.isFirstLaunch {
                    mainContent
                }
                settingsButton
                #if DEBUG
                debugButtons
                #endif
            }
            .navigationBarHidden(true)
            .refreshable {
                isRefreshing = true
                await rssParser.fetchAllFeeds()
                isRefreshing = false
            }
            .overlay {
                if isRefreshing {
                    ProgressView()
                }
            }
        }
        .setupContentView(
            showWelcome: $showWelcome,
            settings: settings,
            rssParser: rssParser,
            scenePhase: scenePhase
        )
    }
    
    private var mainContent: some View {
        Group {
            if rssParser.state.isLoading && rssParser.newsItems.isEmpty {
                ProgressView("Laden...")
            } else {
                HeaderView(lastUpdate: rssParser.state.lastUpdate, currentTime: currentTime)
                NewsFeedView(
                    settings: settings,
                    rssParser: rssParser,
                    readArticlesManager: readArticlesManager
                )
            }
        }
    }
    
    private var settingsButton: some View {
        NavigationLink {
            SettingsView(settings: settings)
        } label: {
            HStack {
                Spacer()
                Image(systemName: "gear")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
    }
    
    #if DEBUG
    private var debugButtons: some View {
        ForEach([
            ("Show Welcome", {
                settings.resetFirstLaunch()
                showWelcome = true
            }),
            ("Reset App State", {
                Settings.resetAllSettings()
                settings.resetFirstLaunch()
                showWelcome = true
            })
        ], id: \.0) { title, action in
            Button(title, action: action)
        }
    }
    #endif
}

// MARK: - Subviews
private struct HeaderView: View {
    let lastUpdate: Date?
    let currentTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Swiss News")
                .font(.title3)
                .fontWeight(.bold)
            if let lastUpdate = lastUpdate {
                Text("Updated: \(timeAgoText(from: lastUpdate, relativeTo: currentTime))")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: -20, leading: 15, bottom: -8, trailing: 15))
    }
}

private struct NewsFeedView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    @ObservedObject var readArticlesManager: ReadArticlesManager
    
    private var relevantCategories: [NewsCategory.CategoryGroup: [NewsCategory]] {
        var filtered: [NewsCategory.CategoryGroup: [NewsCategory]] = [:]
        let allCategories = NewsCategory.categoriesByGroup()
        
        print("\n--- Debug relevantCategories ---")
        print("Selected sources: \(settings.selectedSources)")
        print("Selected categories: \(settings.selectedCategories)")
        
        for (group, categories) in allCategories {
            let relevantCats = categories.filter { category in
                let isRelevant = settings.selectedSources.contains(category.sourceId) && 
                                settings.selectedCategories.contains(category.id)
                print("Category \(category.id): isRelevant=\(isRelevant)")
                return isRelevant
            }
            if !relevantCats.isEmpty {
                filtered[group] = relevantCats
                print("Group \(group): \(relevantCats.map { $0.id })")
            }
        }
        print("-------------------------\n")
        return filtered
    }
    
    var body: some View {
        ForEach(settings.categoryOrder) { group in
            if let categories = relevantCategories[group] {
                ForEach(categories) { category in
                    CategoryRowView(
                        category: category,
                        newsItems: rssParser.newsItems[category.id] ?? [],
                        readArticlesManager: readArticlesManager
                    )
                }
            }
        }
    }
}

private struct CategoryRowView: View {
    let category: NewsCategory
    let newsItems: [NewsItem]
    @ObservedObject var readArticlesManager: ReadArticlesManager
    
    var body: some View {
        NavigationLink {
            NewsCategoryView(
                title: category.title,
                newsItems: newsItems,
                readArticlesManager: readArticlesManager
            )
        } label: {
            SectionHeaderView(
                title: category.title,
                count: newsItems.filter { !readArticlesManager.isRead($0.link) }.count,
                sourceId: category.sourceId
            )
        }
        .onAppear {
            print("Showing category: \(category.id) with \(newsItems.count) items")
        }
    }
}

struct SectionHeaderView: View {
    let title: String
    let count: Int
    let sourceId: String
    
    var body: some View {
        HStack {
            Image(NewsSource.available.first { $0.id == sourceId }?.logoName ?? "")
                .resizable()
                .scaledToFit()
                .frame(height: 16)
                .padding(.trailing, 4)
            
            Text(title)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - View Modifiers
private extension View {
    func setupContentView(
        showWelcome: Binding<Bool>,
        settings: Settings,
        rssParser: RSSFeedParser,
        scenePhase: ScenePhase
    ) -> some View {
        self
            .sheet(isPresented: showWelcome) {
                SourceSelectionView(settings: settings, showWelcome: showWelcome)
            }
            .onAppear {
                print("ContentView appeared")
                print("isFirstLaunch: \(settings.isFirstLaunch)")
                if settings.isFirstLaunch {
                    print("Showing welcome screen")
                    showWelcome.wrappedValue = true
                }
            }
            .task {
                if !settings.isFirstLaunch {
                    await rssParser.fetchAllFeeds()
                }
            }
            .onChange(of: settings.cutoffHours) { _, _ in
                Task {
                    await rssParser.fetchAllFeeds()
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active && !settings.isFirstLaunch {
                    Task {
                        await rssParser.fetchAllFeeds()
                    }
                }
            }
            .alert("Fehler", isPresented: Binding(
                get: { rssParser.state.error != nil },
                set: { if !$0 { rssParser.resetState() } }
            )) {
                Button("OK", role: .cancel) {
                    rssParser.resetState()
                }
                Button("Erneut versuchen") {
                    Task {
                        await rssParser.fetchAllFeeds()
                    }
                }
            } message: {
                if let error = rssParser.state.error {
                    Text(error.localizedDescription)
                    if let recovery = error.recoverySuggestion {
                        Text(recovery)
                    }
                }
            }
    }
}

#Preview {
    ContentView()
}
