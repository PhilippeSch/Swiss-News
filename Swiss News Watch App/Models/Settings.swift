import Foundation

class Settings: ObservableObject {
    @Published var cutoffHours: Double {
        didSet {
            saveCutoffHours()
        }
    }
    @Published var selectedCategories: Set<String> {
        didSet {
            saveSelectedCategories()
        }
    }
    @Published var categoryOrder: [NewsCategory.CategoryGroup]
    @Published var selectedSources: Set<String> {
        didSet {
            saveSelectedSources()
        }
    }
    
    private let currentAppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    private let lastLaunchedVersion = UserDefaults.standard.string(forKey: "lastLaunchedVersion")
    
    private static let firstLaunchKey = "com.scheuber.swissnews.firstLaunch"
    
    private var isBatchUpdating = false
    private var hasChanges = false
    
    private var pendingCategoryChanges: Set<String>?
    private var pendingSourceChanges: Set<String>?
    
    private let defaults = UserDefaults.standard
    
    var isFirstLaunch: Bool {
        get { defaults.object(forKey: Constants.UserDefaults.firstLaunchKey) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Constants.UserDefaults.firstLaunchKey) }
    }
    
    init() {
        // First initialize all stored properties
        let storedHours = UserDefaults.standard.double(forKey: Constants.UserDefaults.cutoffHoursKey)
        self.cutoffHours = storedHours == 0 ? 48.0 : storedHours
        
        // Initialize categories
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaults.selectedCategoriesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.selectedCategories = decoded
        } else {
            self.selectedCategories = Set(NewsCategory.available
                .filter { $0.sourceId == "srf" && ($0.id.contains("news") || $0.id == "srf_sport_all") }
                .map { $0.id })
        }
        
        // Initialize sources
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaults.selectedSourcesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.selectedSources = decoded
        } else {
            self.selectedSources = ["srf"]
        }
        
        // Initialize category order
        if let data = UserDefaults.standard.data(forKey: "categoryOrder"),
           let decoded = try? JSONDecoder().decode([NewsCategory.CategoryGroup].self, from: data) {
            self.categoryOrder = decoded
        } else {
            self.categoryOrder = NewsCategory.CategoryGroup.allCases.sorted(by: { $0.sortOrder < $1.sortOrder })
        }
        
        // After all properties are initialized, setup observers
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
        selectedCategories = Set(NewsCategory.available
            .filter { $0.sourceId == "srf" && ($0.id.contains("news") || $0.id == "srf_sport_all") }
            .map { $0.id })
        selectedSources = ["srf"]
        cutoffHours = 48.0
        
        // Speichert die Standardwerte
        saveSelectedCategories()
        saveSelectedSources()
    }
    
    func beginBatchUpdate() {
        isBatchUpdating = true
    }
    
    func endBatchUpdate() {
        isBatchUpdating = false
        if hasChanges {
            // Trigger a single update after all changes are complete
            objectWillChange.send()
            hasChanges = false
        }
    }
    
    func saveSelectedCategories() {
        if let encoded = try? JSONEncoder().encode(selectedCategories) {
            defaults.set(encoded, forKey: Constants.UserDefaults.selectedCategoriesKey)
        }
    }
    
    func saveSelectedSources() {
        if let encoded = try? JSONEncoder().encode(selectedSources) {
            defaults.set(encoded, forKey: Constants.UserDefaults.selectedSourcesKey)
        }
    }
    
    func saveCutoffHours() {
        defaults.set(cutoffHours, forKey: Constants.UserDefaults.cutoffHoursKey)
    }
    
    func resetFirstLaunch() {
        print("Resetting first launch state")
        isFirstLaunch = true
    }
    
    func beginSettingsSession() {
        // Store current state as pending changes
        pendingCategoryChanges = selectedCategories
        pendingSourceChanges = selectedSources
    }
    
    func commitSettingsChanges() {
        // Only save if there were actual changes
        if pendingCategoryChanges != selectedCategories {
            saveSelectedCategories()
        }
        if pendingSourceChanges != selectedSources {
            saveSelectedSources()
        }
        
        // Clear pending changes
        pendingCategoryChanges = nil
        pendingSourceChanges = nil
    }
    
    func discardSettingsChanges() {
        // Restore original state if needed
        if let originalCategories = pendingCategoryChanges {
            selectedCategories = originalCategories
        }
        if let originalSources = pendingSourceChanges {
            selectedSources = originalSources
        }
        
        // Clear pending changes
        pendingCategoryChanges = nil
        pendingSourceChanges = nil
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
} 
