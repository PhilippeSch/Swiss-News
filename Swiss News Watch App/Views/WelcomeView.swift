import SwiftUI

struct WelcomeView: View {
    @ObservedObject var settings: Settings
    @ObservedObject var rssParser: RSSFeedParser
    @Binding var showWelcome: Bool
    var sourceId: String?
    var onCompletion: (() -> Void)?
    
    @Namespace private var scrollSpace
    
    init(settings: Settings, rssParser: RSSFeedParser, showWelcome: Binding<Bool>, sourceId: String? = nil, onCompletion: (() -> Void)? = nil) {
        self._settings = ObservedObject(wrappedValue: settings)
        self._rssParser = ObservedObject(wrappedValue: rssParser)
        self._showWelcome = showWelcome
        self.sourceId = sourceId
        self.onCompletion = onCompletion
    }
    
    private var relevantCategories: [NewsCategory.CategoryGroup: [NewsCategory]] {
        var filtered: [NewsCategory.CategoryGroup: [NewsCategory]] = [:]
        let allCategories = NewsCategory.categoriesByGroup()
        
        for (group, categories) in allCategories {
            let relevantCats = categories.filter { sourceId == nil || $0.sourceId == sourceId }
            if !relevantCats.isEmpty {
                filtered[group] = relevantCats
            }
        }
        return filtered
    }
    
    private var allRelevantCategoryIds: [String] {
        relevantCategories.values.flatMap { $0.map { $0.id } }
    }
    
    private var areAllSelected: Bool {
        !allRelevantCategoryIds.isEmpty && allRelevantCategoryIds.allSatisfy { settings.selectedCategories.contains($0) }
    }
    
    private func toggleAllCategories() {
        if areAllSelected {
            // Unselect all
            for categoryId in allRelevantCategoryIds {
                settings.selectedCategories.remove(categoryId)
            }
        } else {
            // Select all
            for categoryId in allRelevantCategoryIds {
                settings.selectedCategories.insert(categoryId)
            }
        }
        settings.saveSelectedCategories()
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    Color.clear
                        .frame(height: 0)
                        .id(scrollSpace)
                    
                    Text("Wähle deine bevorzugten Kategorien:")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    
                    Button(areAllSelected ? String(localized: "Alle abwählen") : String(localized: "Alle auswählen")) {
                        toggleAllCategories()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    ForEach(settings.categoryOrder) { group in
                        if let categories = relevantCategories[group] {
                            VStack(alignment: .leading) {
                                Text(group.title)
                                    .font(.headline)
                                
                                ForEach(categories) { category in
                                    if sourceId == nil || category.sourceId == sourceId {
                                        Toggle(category.title, isOn: Binding(
                                            get: { settings.selectedCategories.contains(category.id) },
                                            set: { isSelected in
                                                if isSelected {
                                                    settings.selectedCategories.insert(category.id)
                                                } else {
                                                    settings.selectedCategories.remove(category.id)
                                                }
                                                settings.saveSelectedCategories()
                                            }
                                        ))
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    
                    Button(String(localized: "Fertig")) {
                        handleCompletion()
                    }
                    .buttonStyle(.bordered)
                    .disabled(settings.selectedCategories.isEmpty)
                    .padding(.top)
                }
                .padding()
            }
            .onAppear {
                // Sofort zum Anfang scrollen
                proxy.scrollTo(scrollSpace, anchor: .top)
            }
            .onChange(of: sourceId) { _, _ in
                // Bei Änderung der Quelle zum Anfang scrollen
                withAnimation {
                    proxy.scrollTo(scrollSpace, anchor: .top)
                }
            }
        }
    }
    
    private func handleCompletion() {
        if let completion = onCompletion {
            completion()
        } else {
            settings.isFirstLaunch = false
            showWelcome = false
            
            // Feeds initial laden
            Task {
                await rssParser.fetchAllFeeds()
            }
        }
    }
} 
