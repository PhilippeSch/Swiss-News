//
//  ContentView.swift
//  Swiss News Watch App
//
//  Created by Philippe Scheuber on 31.12.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = Settings()
    @StateObject private var rssParser: RSSFeedParser
    @StateObject private var readArticlesManager = ReadArticlesManager()
    @State private var currentTime = Date()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isRefreshing = false
    @State private var showWelcome = false
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init() {
        let settings = Settings()
        self._settings = StateObject(wrappedValue: settings)
        self._rssParser = StateObject(wrappedValue: RSSFeedParser(settings: settings))
    }
    
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                List {
                    HeaderView(
                        lastUpdate: rssParser.state.lastUpdate,
                        currentTime: currentTime,
                        rssParser: rssParser
                    )
                    .id("top")
                    
                    NewsFeedView(
                        settings: settings,
                        rssParser: rssParser,
                        readArticlesManager: readArticlesManager
                    )
                    
                    SettingsButton(settings: settings, rssParser: rssParser)
                    
                    #if DEBUG
                    DebugSection(
                        settings: settings,
                        rssParser: rssParser,
                        showWelcome: $showWelcome
                    )
                    #endif
                }
                .listStyle(.plain)
                .refreshable {
                    await rssParser.fetchAllFeeds()
                }
                .task {
                    await MainActor.run {
                        withAnimation {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                }
                .onChange(of: rssParser.state.lastUpdate) { _, _ in
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
        .onAppear {
            showWelcome = settings.isFirstLaunch
            Task {
                await rssParser.fetchAllFeeds()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
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
        .alert("Fehler beim Laden", isPresented: .init(
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

private struct SettingsButton: View {
    let settings: Settings
    let rssParser: RSSFeedParser
    
    var body: some View {
        NavigationLink {
            SettingsView(settings: settings, rssParser: rssParser)
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
            ForEach([
                ("Reset App State", {
                    Settings.resetAllSettings()
                    settings.resetToDefaults()
                    settings.resetFirstLaunch()
                    rssParser.reset()
                    showWelcome = true
                }),
                ("Show Welcome", {
                    settings.resetFirstLaunch()
                    showWelcome = true
                })
            ], id: \.0) { title, action in
                Button(action: action) {
                    Text(title)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.bordered)
                .listRowInsets(EdgeInsets(top: 4, leading: 15, bottom: 4, trailing: 15))
            }
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

#Preview {
    ContentView()
}
