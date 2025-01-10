import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            timeFilterSection
            sourcesSection
            versionSection
        }
        .navigationTitle("Einstellungen")
        .onAppear {
            print("📱 SettingsView Body appeared")
            rssParser.setSettingsViewActive(true)
            settings.beginSettingsSession()
        }
        .onDisappear {
            if !rssParser.isSettingsViewActive {  // Only commit if actually dismissing
                print("📱 SettingsView Body disappeared - committing changes")
                settings.commitSettingsChanges()
            }
        }
    }
    
    private var timeFilterSection: some View {
        Section(header: Text("Artikel Filter")) {
            Picker("Zeitraum", selection: $settings.cutoffHours) {
                Text("Keine Limite").tag(0.0)
                Text("24 Stunden").tag(24.0)
                Text("48 Stunden").tag(48.0)
                Text("72 Stunden").tag(72.0)
            }
        }
    }
    
    private var sourcesSection: some View {
        Section(
            header: Text("Nachrichtenquellen"),
            footer: Text("Tippe auf eine Quelle um die Kategorien auszuwählen →")
                .font(.caption)
                .foregroundColor(.gray)
        ) {
            ForEach(NewsSource.available) { source in
                NavigationLink {
                    SourceCategoriesView(source: source, settings: settings, rssParser: rssParser)
                } label: {
                    HStack {
                        Image(source.logoName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                        
                        Text(source.name)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { settings.selectedSources.contains(source.id) },
                            set: { isSelected in
                                if isSelected {
                                    settings.selectedSources.insert(source.id)
                                } else {
                                    settings.selectedSources.remove(source.id)
                                    settings.selectedCategories = settings.selectedCategories.filter { !$0.starts(with: "\(source.id)_") }
                                }
                                settings.saveSelectedSources()
                            }
                        ))
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var versionSection: some View {
        Section {
            Text("Build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown")")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct SourceCategoriesView: View {
    let source: NewsSource
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    
    var body: some View {
        Form {
            ForEach(settings.categoryOrder) { group in
                let sourceCategories = NewsCategory.categoriesByGroup()[group]?
                    .filter { $0.sourceId == source.id } ?? []
                
                if !sourceCategories.isEmpty {
                    Section(header: Text(group.title)) {
                        ForEach(sourceCategories) { category in
                            CategoryToggle(
                                category: category,
                                settings: settings,
                                sourceId: source.id
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle(source.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("📱 Category selector appeared")
        }
        .onDisappear {
            print("📱 Category selector disappeared")
        }
    }
}

private struct CategoryToggle: View {
    let category: NewsCategory
    @ObservedObject var settings: Settings
    let sourceId: String
    @State private var isToggled: Bool = false
    
    var body: some View {
        Toggle(category.title, isOn: $isToggled)
            .disabled(!settings.selectedSources.contains(sourceId))
            .onAppear {
                isToggled = settings.selectedCategories.contains(category.id)
            }
            .onChange(of: isToggled) { _, newValue in
                updateSettings(newValue)
            }
    }
    
    private func checkOtherCategories() -> Bool {
        let sameSourceCategories = NewsCategory.available.filter { 
            $0.sourceId == sourceId && $0.id != category.id 
        }
        
        return sameSourceCategories.contains { category in
            settings.selectedCategories.contains(category.id)
        }
    }
    
    private func updateSettings(_ isSelected: Bool) {
        if isSelected {
            settings.selectedCategories.insert(category.id)
            settings.selectedSources.insert(sourceId)
        } else {
            settings.selectedCategories.remove(category.id)
            if !checkOtherCategories() {
                settings.selectedSources.remove(sourceId)
            }
        }
    }
} 
