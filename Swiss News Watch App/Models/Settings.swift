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
        if let data = UserDefaults.standard.data(forKey: Constants.UserDefaults.categoryOrderKey),
           let decoded = try? JSONDecoder().decode([NewsCategory.CategoryGroup].self, from: data) {
            self.categoryOrder = decoded
        } else {
            self.categoryOrder = NewsCategory.CategoryGroup.allCases.sorted(by: { $0.sortOrder < $1.sortOrder })
        }
        
        // After all properties are initialized, setup observers
        setupObservers()
    }
    
    private func setupObservers() {
        let defaults = UserDefaults.standard

        if !defaults.bool(forKey: Constants.UserDefaults.selectedCategoriesInitializedKey) {
            if let encoded = try? JSONEncoder().encode(Array(selectedCategories)) {
                defaults.set(encoded, forKey: Constants.UserDefaults.selectedCategoriesKey)
                defaults.set(true, forKey: Constants.UserDefaults.selectedCategoriesInitializedKey)
            }
        }

        if defaults.double(forKey: Constants.UserDefaults.cutoffHoursKey) == 0 {
            defaults.set(self.cutoffHours, forKey: Constants.UserDefaults.cutoffHoursKey)
        }
    }

    #if DEBUG
    static func resetAllSettings() {
        // Löscht alle UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        // Setzt Default-Werte zurück
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Constants.UserDefaults.selectedCategoriesKey)
        defaults.removeObject(forKey: Constants.UserDefaults.selectedSourcesKey)
        defaults.removeObject(forKey: Constants.UserDefaults.categoryOrderKey)
        defaults.removeObject(forKey: Constants.UserDefaults.cutoffHoursKey)
        defaults.removeObject(forKey: Constants.UserDefaults.selectedCategoriesInitializedKey)
        defaults.removeObject(forKey: Constants.UserDefaults.firstLaunchKey)
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
    
}

