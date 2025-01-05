import Foundation

class Settings: ObservableObject {
    @Published var cutoffHours: Double
    @Published var selectedCategories: Set<String>
    @Published var categoryOrder: [NewsCategory.CategoryGroup]
    
    var isFirstLaunch: Bool {
        get { UserDefaults.standard.bool(forKey: "hasLaunched") == false }
        set { UserDefaults.standard.set(!newValue, forKey: "hasLaunched") }
    }
    
    init() {
        // Initialize all stored properties first
        let storedHours = UserDefaults.standard.double(forKey: "cutoffHours")
        self.cutoffHours = storedHours == 0 ? 48 : storedHours
        
        // Initialize selected categories
        if let data = UserDefaults.standard.data(forKey: "selectedCategories"),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.selectedCategories = Set(decoded)
        } else {
            self.selectedCategories = Set([
                "news_all",        // News
                "sport_all",       // Sport
                "culture_all",     // Kultur
                "knowledge_all"    // Wissen
            ])
        }
        
        // Initialize category order
        if let data = UserDefaults.standard.data(forKey: "categoryOrder"),
           let decoded = try? JSONDecoder().decode([NewsCategory.CategoryGroup].self, from: data) {
            self.categoryOrder = decoded
        } else {
            self.categoryOrder = NewsCategory.CategoryGroup.allCases.sorted(by: { $0.sortOrder < $1.sortOrder })
        }
        
        // Setup observers after initialization
        setupObservers()
    }
    
    private func setupObservers() {
        if !UserDefaults.standard.bool(forKey: "selectedCategoriesInitialized") {
            if let encoded = try? JSONEncoder().encode(Array(selectedCategories)) {
                UserDefaults.standard.set(encoded, forKey: "selectedCategories")
                UserDefaults.standard.set(true, forKey: "selectedCategoriesInitialized")
            }
        }
        
        if UserDefaults.standard.double(forKey: "cutoffHours") == 0 {
            UserDefaults.standard.set(self.cutoffHours, forKey: "cutoffHours")
        }
    }
    
    #if DEBUG
    static func resetAllSettings() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    #endif
}

extension Settings {
    func saveCutoffHours() {
        UserDefaults.standard.set(cutoffHours, forKey: "cutoffHours")
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
    
    func saveSelectedCategories() {
        if let encoded = try? JSONEncoder().encode(Array(selectedCategories)) {
            UserDefaults.standard.set(encoded, forKey: "selectedCategories")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    func resetFirstLaunch() {
        UserDefaults.standard.removeObject(forKey: "hasLaunched")
        UserDefaults.standard.removeObject(forKey: "selectedCategoriesInitialized")
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
} 