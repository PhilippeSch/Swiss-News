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
    @StateObject private var settings = Settings()
    @StateObject private var rssParser: RSSFeedParser
    @State private var currentTime = Date()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isRefreshing = false
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    init() {
        let settings = Settings()
        _settings = StateObject(wrappedValue: settings)
        _rssParser = StateObject(wrappedValue: RSSFeedParser(settings: settings))
    }
    
    var body: some View {
        NavigationView {
            List {
                Group {
                    if rssParser.isLoading && rssParser.generalNews.isEmpty {
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
                        
                        if !rssParser.generalNews.isEmpty {
                            NavigationLink {
                                NewsCategoryView(title: "Allgemein", newsItems: rssParser.generalNews)
                            } label: {
                                SectionHeaderView(title: "Allgemein", count: rssParser.generalNews.count)
                            }
                        }
                        
                        if !rssParser.internationalNews.isEmpty {
                            NavigationLink {
                                NewsCategoryView(title: "International", newsItems: rssParser.internationalNews)
                            } label: {
                                SectionHeaderView(title: "International", count: rssParser.internationalNews.count)
                            }
                        }
                        
                        if !rssParser.economyNews.isEmpty {
                            NavigationLink {
                                NewsCategoryView(title: "Wirtschaft", newsItems: rssParser.economyNews)
                            } label: {
                                SectionHeaderView(title: "Wirtschaft", count: rssParser.economyNews.count)
                            }
                        }
                        
                        if !rssParser.scienceNews.isEmpty {
                            NavigationLink {
                                NewsCategoryView(title: "Wissen", newsItems: rssParser.scienceNews)
                            } label: {
                                SectionHeaderView(title: "Wissen", count: rssParser.scienceNews.count)
                            }
                        }
                        
                        if !rssParser.sportNews.isEmpty {
                            NavigationLink {
                                NewsCategoryView(title: "Sport", newsItems: rssParser.sportNews)
                            } label: {
                                SectionHeaderView(title: "Sport", count: rssParser.sportNews.count)
                            }
                        }
                        
                        if !rssParser.cultureNews.isEmpty {
                            NavigationLink {
                                NewsCategoryView(title: "Kultur", newsItems: rssParser.cultureNews)
                            } label: {
                                SectionHeaderView(title: "Kultur", count: rssParser.cultureNews.count)
                            }
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
