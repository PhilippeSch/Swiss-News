import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: Settings
    private let groupedCategories = NewsCategory.categoriesByGroup()
    
    private var versionInfo: String {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        return "Build \(build)"
    }
    
    var body: some View {
        Form {
            Section(header: Text("Artikel Filter")) {
                Picker("Zeitraum", selection: $settings.cutoffHours) {
                    Text("Keine Limite").tag(0.0)
                    Text("24 Stunden").tag(24.0)
                    Text("48 Stunden").tag(48.0)
                    Text("72 Stunden").tag(72.0)
                }
            }
            
            Section(header: Text("Kategorien Reihenfolge")) {
                ForEach(settings.categoryOrder.indices, id: \.self) { index in
                    HStack {
                        Text(settings.categoryOrder[index].title)
                        Spacer()
                        if index > 0 {
                            Button {
                                settings.categoryOrder.swapAt(index, index - 1)
                            } label: {
                                Image(systemName: "chevron.up")
                            }
                        }
                        if index < settings.categoryOrder.count - 1 {
                            Button {
                                settings.categoryOrder.swapAt(index, index + 1)
                            } label: {
                                Image(systemName: "chevron.down")
                            }
                        }
                    }
                }
            }
            
            ForEach(settings.categoryOrder) { group in
                Section(header: Text(group.title)) {
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
            }
            
            Section {
                Text(versionInfo)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Einstellungen")
    }
}

extension NewsCategory.CategoryGroup {
    var title: String {
        switch self {
        case .news: return "News"
        case .sport: return "Sport"
        case .culture: return "Kultur"
        case .knowledge: return "Wissen"
        }
    }
} 
