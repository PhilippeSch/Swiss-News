import SwiftUI

struct WelcomeView: View {
    @ObservedObject var settings: Settings
    @Binding var showWelcome: Bool
    var sourceId: String? = nil
    var onCompletion: (() -> Void)? = nil
    
    private let groupedCategories = NewsCategory.categoriesByGroup()
    
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Wähle deine bevorzugten Kategorien:")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                ForEach(settings.categoryOrder) { group in
                    if let categories = relevantCategories[group] {
                        VStack(alignment: .leading) {
                            Text(group.title)
                                .font(.headline)
                            
                            ForEach(categories) { category in
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
                        .padding(.vertical, 5)
                    }
                }
                
                Button("Fertig") {
                    if let completion = onCompletion {
                        completion()
                    } else {
                        settings.isFirstLaunch = false
                        showWelcome = false
                    }
                }
                .buttonStyle(.bordered)
                .disabled(settings.selectedCategories.isEmpty)
                .padding(.top)
            }
            .padding()
        }
    }
} 
