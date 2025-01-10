import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    @State private var expandedSource: String?
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
        }
        .onDisappear {
            print("📱 SettingsView Body disappeared")
            rssParser.setSettingsViewActive(false)
        }
        .onChange(of: settings.selectedCategories) { oldValue, newValue in
            print("🔄 Selected categories changed in SettingsView")
            print("Old value: \(oldValue)")
            print("New value: \(newValue)")
        }
        .onChange(of: settings.selectedSources) { oldValue, newValue in
            print("🔄 Selected sources changed in SettingsView")
            print("Old value: \(oldValue)")
            print("New value: \(newValue)")
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
        Section(header: Text("Nachrichtenquellen")) {
            ForEach(NewsSource.available) { source in
                SourceRow(
                    source: source,
                    isExpanded: expandedSource == source.id,
                    settings: settings,
                    onToggle: { isExpanded in
                        withAnimation {
                            expandedSource = isExpanded ? source.id : nil
                        }
                    }
                )
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

private struct SourceRow: View {
    let source: NewsSource
    let isExpanded: Bool
    @ObservedObject var settings: Settings
    let onToggle: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            sourceHeader
            if isExpanded {
                categoryList
            }
        }
    }
    
    private var sourceHeader: some View {
        Button(action: { onToggle(!isExpanded) }) {
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
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
        .foregroundColor(.primary)
    }
    
    private var categoryList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(settings.categoryOrder) { group in
                let sourceCategories = NewsCategory.categoriesByGroup()[group]?
                    .filter { $0.sourceId == source.id } ?? []
                
                if !sourceCategories.isEmpty {
                    CategoryGroup(
                        group: group,
                        categories: sourceCategories,
                        settings: settings,
                        sourceId: source.id
                    )
                }
            }
        }
        .padding(.leading)
        .padding(.top, 8)
    }
}

private struct CategoryGroup: View {
    let group: NewsCategory.CategoryGroup
    let categories: [NewsCategory]
    @ObservedObject var settings: Settings
    let sourceId: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(group.title)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 4)
            
            ForEach(categories) { category in
                CategoryToggle(
                    category: category,
                    settings: settings,
                    sourceId: sourceId
                )
            }
        }
    }
}

private struct CategoryToggle: View {
    let category: NewsCategory
    @ObservedObject var settings: Settings
    let sourceId: String
    
    var body: some View {
        Toggle(category.title, isOn: Binding(
            get: { settings.selectedCategories.contains(category.id) },
            set: { isSelected in
                settings.beginBatchUpdate()
                updateSettings(isSelected)
                settings.saveSelectedCategories()
                settings.saveSelectedSources()
                settings.endBatchUpdate()
            }
        ))
        .disabled(!settings.selectedSources.contains(sourceId))
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
