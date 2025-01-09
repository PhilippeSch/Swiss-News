import Foundation

class Settings: ObservableObject {
    @Published var cutoffHours: Double
    @Published var selectedCategories: Set<String>
    @Published var categoryOrder: [NewsCategory.CategoryGroup]
    @Published var selectedSources: Set<String>
    
    private let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let lastLaunchedVersion = UserDefaults.standard.string(forKey: "lastLaunchedVersion")
    
    private static let firstLaunchKey = "com.scheuber.swissnews.firstLaunch"
    
    var isFirstLaunch: Bool {
        get {
            // Check if we've stored the first launch key
            let hasKey = UserDefaults.standard.object(forKey: Settings.firstLaunchKey) != nil
            return !hasKey
        }
        set {
            if !newValue {
                UserDefaults.standard.set(true, forKey: Settings.firstLaunchKey)
            }
        }
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
            self.selectedCategories = NewsCategory.defaultCategories
        }
        
        // Initialize category order
        if let data = UserDefaults.standard.data(forKey: "categoryOrder"),
           let decoded = try? JSONDecoder().decode([NewsCategory.CategoryGroup].self, from: data) {
            self.categoryOrder = decoded
        } else {
            self.categoryOrder = NewsCategory.CategoryGroup.allCases.sorted(by: { $0.sortOrder < $1.sortOrder })
        }
        
        // Initialize selected sources
        if let data = UserDefaults.standard.data(forKey: "selectedSources"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.selectedSources = decoded
        } else {
            self.selectedSources = NewsSource.defaultSources
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
        print("Resetting all settings")
        // Löscht alle UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Löscht den App Container
        if let appDomain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        }
        
        // Setzt Default-Werte zurück
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "selectedCategories")
        defaults.removeObject(forKey: "selectedSources")
        defaults.removeObject(forKey: "categoryOrder")
        defaults.removeObject(forKey: "cutoffHours")
        defaults.removeObject(forKey: "selectedCategoriesInitialized")
        defaults.removeObject(forKey: Settings.firstLaunchKey)
        
        // Synchronisiert UserDefaults
        defaults.synchronize()
    }
    #endif
    
    func resetToDefaults() {
        selectedCategories = NewsCategory.defaultCategories
        selectedSources = NewsSource.defaultSources
        categoryOrder = NewsCategory.CategoryGroup.allCases.sorted(by: { $0.sortOrder < $1.sortOrder })
        cutoffHours = 48.0
        
        // Speichert die Standardwerte
        saveSelectedCategories()
        saveSelectedSources()
    }
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
        print("Resetting first launch state")
        UserDefaults.standard.removeObject(forKey: Settings.firstLaunchKey)
    }
    
    func saveSelectedSources() {
        if let encoded = try? JSONEncoder().encode(selectedSources) {
            UserDefaults.standard.set(encoded, forKey: "selectedSources")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
} 
