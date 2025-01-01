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
    @StateObject private var rssParser = RSSFeedParser()
    
    var body: some View {
        NavigationView {
            List {
                Group {
                    if rssParser.isLoading && rssParser.generalNews.isEmpty {
                        ProgressView("Laden...")
                    } else {
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
            }
            .navigationTitle("SRF News")
            .refreshable {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await rssParser.fetchAllFeeds()
            }
        }
        .task {
            await rssParser.fetchAllFeeds()
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
