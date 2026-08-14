//
//  ContentView.swift
//  Swiss News Watch App
//
//  Created by Philippe Scheuber on 31.12.2024.
//

import SwiftUI
import WatchKit

// Add this at the top of the file, outside any struct
private struct ScrollPositionIdKey: EnvironmentKey {
    static let defaultValue: Binding<String?> = .constant(nil)
}

extension EnvironmentValues {
    var scrollPositionId: Binding<String?> {
        get { self[ScrollPositionIdKey.self] }
        set { self[ScrollPositionIdKey.self] = newValue }
    }
}

struct ContentView: View {
    @StateObject private var settings = Settings()
    @StateObject private var rssParser: RSSFeedParser
    @StateObject private var readArticlesManager = ReadArticlesManager()
    @State private var currentTime = Date()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isRefreshing = false
    @State private var showWelcome = false
    @State private var scrollPosition: String? = nil
    @State private var hasCheckedFirstLaunch = false
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init() {
        let settings = Settings()
        self._settings = StateObject(wrappedValue: settings)
        self._rssParser = StateObject(wrappedValue: RSSFeedParser(settings: settings))
    }
    
    var body: some View {
        NavigationStack {
            List {
                HeaderView(
                    lastUpdate: rssParser.state.lastUpdate,
                    currentTime: currentTime,
                    rssParser: rssParser
                )
                .id("top")
                .listRowInsets(EdgeInsets(top: -20, leading: 15, bottom: -8, trailing: 15))
                .listRowBackground(Color.clear)

                NewsFeedView(
                    settings: settings,
                    rssParser: rssParser,
                    readArticlesManager: readArticlesManager
                )
                
                SettingsButton(settings: settings, rssParser: rssParser, showWelcome: $showWelcome)
                
                #if DEBUG
                DebugSection(
                    settings: settings,
                    rssParser: rssParser,
                    showWelcome: $showWelcome
                )
                #endif
            }
            .navigationDestination(for: CategoryNavigationValue.self) { navigationValue in
                if let category = NewsCategory.available.first(where: { $0.id == navigationValue.categoryId }) {
                    NewsCategoryView(
                        title: category.title,
                        newsItems: rssParser.newsItems[navigationValue.categoryId] ?? [],
                        readArticlesManager: readArticlesManager
                    )
                    .onAppear {
                        scrollPosition = "category_\(navigationValue.categoryId)"
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                // Manual refresh always fetches, regardless of cache age.
                await rssParser.fetchAllFeeds(force: true)
            }
            .task {
                guard !ProcessInfo.processInfo.isRunningInPreview else { return }
                // Show the last known articles first, then refresh behind them.
                await rssParser.loadCachedContent()
                await rssParser.fetchAllFeeds()
            }
            .onAppear {
                // Only check first launch once, not every time the view appears
                if !hasCheckedFirstLaunch {
                    showWelcome = settings.isFirstLaunch
                    hasCheckedFirstLaunch = true
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active, !ProcessInfo.processInfo.isRunningInPreview {
                    Task {
                        // Throttled: a wrist-raise within the validity window is a no-op.
                        await rssParser.fetchAllFeeds()
                    }
                }
            }
            .onReceive(timer) { time in
                currentTime = time
            }
            .sheet(isPresented: $showWelcome) {
                SourceSelectionView(
                    settings: settings,
                    rssParser: rssParser,
                    showWelcome: $showWelcome
                )
            }
            .alert(String(localized: "Fehler beim Laden"), isPresented: .init(
                get: { rssParser.state.error != nil },
                set: { if !$0 { rssParser.resetState() } }
            )) {
                Button(String(localized: "OK"), role: .cancel) {
                    rssParser.resetState()
                }
                Button(String(localized: "Erneut versuchen")) {
                    Task {
                        await rssParser.fetchAllFeeds(force: true)
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
        .environment(\.scrollPositionId, $scrollPosition)
    }
}

private struct SettingsButton: View {
    let settings: Settings
    let rssParser: RSSFeedParser
    @Binding var showWelcome: Bool
    
    var body: some View {
        NavigationLink {
            SettingsView(settings: settings, rssParser: rssParser, showWelcome: $showWelcome)
        } label: {
            Image(systemName: "gear")
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .accessibilityIdentifier("settingsButton")
    }
}

#if DEBUG
private struct DebugSection: View {
    let settings: Settings
    let rssParser: RSSFeedParser
    @Binding var showWelcome: Bool
    
    var body: some View {
        Section {
            Button {
                Settings.resetAllSettings()
                settings.resetToDefaults()
                settings.resetFirstLaunch()
                rssParser.reset()
                showWelcome = true
            } label: {
                Text(String(localized: "Reset App State"))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.bordered)
            .listRowInsets(EdgeInsets(top: 4, leading: 15, bottom: 4, trailing: 15))
        }
        .listRowBackground(Color.clear)
    }
}
#endif

private struct HeaderView: View {
    let lastUpdate: Date?
    let currentTime: Date
    @ObservedObject var rssParser: RSSFeedParser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Swiss News")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityIdentifier("appHeader")
            if rssParser.state.isLoading {
                Text("News Feeds updating...")
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else if let lastUpdate = lastUpdate {
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

extension ProcessInfo {
    /// True when the process is running inside an Xcode SwiftUI preview.
    var isRunningInPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

#Preview {
    ContentView()
}
