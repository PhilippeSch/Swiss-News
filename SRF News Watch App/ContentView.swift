//
//  ContentView.swift
//  SRF News Watch App
//
//  Created by Philippe Scheuber on 31.12.2024.
//

import SwiftUI
import WatchKit
import AuthenticationServices

struct ContentView: View {
    @StateObject private var settings: Settings
    @StateObject private var rssParser: RSSFeedParser
    @State private var currentTime = Date()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isRefreshing = false
    @State private var showWelcome = false
    @State private var showError = false
    private let groupedCategories = NewsCategory.categoriesByGroup()
    
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
                Group {
                    if rssParser.isLoading && rssParser.newsItems.isEmpty {
                        ProgressView("Laden...")
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .center, spacing: 4) {
                                Image("srf_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 16)
                                    .padding(.top, 2)
                                Text("News")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            if let lastUpdate = rssParser.lastUpdate {
                                Text("Updated: \(timeAgoText(from: lastUpdate, relativeTo: currentTime))")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: -20, leading: 15, bottom: -8, trailing: 15))
                        
                        ForEach(settings.categoryOrder) { group in
                            if let categories = groupedCategories[group] {
                                ForEach(categories.filter { settings.selectedCategories.contains($0.id) }) { category in
                                    if let items = rssParser.newsItems[category.id], !items.isEmpty {
                                        NavigationLink {
                                            NewsCategoryView(title: category.title, newsItems: items)
                                        } label: {
                                            SectionHeaderView(title: category.title, count: items.count)
                                        }
                                    }
                                }
                            }
                        }
                        .onChange(of: settings.selectedCategories) { _, newValue in
                            print("Selected categories: \(newValue)")
                        }
                        .onChange(of: rssParser.newsItems) { _, newValue in
                            print("News items: \(newValue.keys)")
                        }
                    }
                }
                
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
                
                #if DEBUG
                Button("Show Welcome") {
                    settings.resetFirstLaunch()
                    showWelcome = true
                }
                Button("Reset App State") {
                    Settings.resetAllSettings()
                    settings.resetFirstLaunch()
                    showWelcome = true
                }
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
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
        .sheet(isPresented: $showWelcome) {
            WelcomeView(settings: settings, showWelcome: $showWelcome)
        }
        .onAppear {
            print("ContentView appeared")
            print("isFirstLaunch: \(settings.isFirstLaunch)")
            if settings.isFirstLaunch {
                print("Showing welcome screen")
                showWelcome = true
            }
        }
        .task {
            await rssParser.fetchAllFeeds()
        }
        .onChange(of: settings.cutoffHours) { _, _ in
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
        .alert("Fehler", isPresented: Binding(
            get: { rssParser.error != nil },
            set: { if !$0 { rssParser.error = nil } }
        )) {
            Button("OK", role: .cancel) {
                rssParser.error = nil
            }
            Button("Erneut versuchen") {
                Task {
                    await rssParser.fetchAllFeeds()
                }
            }
        } message: {
            if let error = rssParser.error {
                Text(error.localizedDescription)
                if let recovery = error.recoverySuggestion {
                    Text(recovery)
                }
            }
        }
    }
}

struct SectionHeaderView: View {
    let title: String
    let count: Int
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    ContentView()
}
