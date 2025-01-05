import SwiftUI

struct WelcomeView: View {
    @ObservedObject var settings: Settings
    @Binding var showWelcome: Bool
    private let groupedCategories = NewsCategory.categoriesByGroup()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Hallo 👋")
                    .font(.title2)
                    .padding(.top)
                
                Text("Wähle deine bevorzugten Nachrichten:")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                
                ForEach(settings.categoryOrder) { group in
                    VStack(alignment: .leading) {
                        Text(group.title)
                            .font(.headline)
                        
                        if let categories = groupedCategories[group] {
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
                    }
                    .padding(.vertical, 5)
                }
                
                Button("Fertig") {
                    settings.isFirstLaunch = false
                    showWelcome = false
                }
                .buttonStyle(.bordered)
                .disabled(settings.selectedCategories.isEmpty)
                .padding(.top)
            }
            .padding()
        }
    }
} 
