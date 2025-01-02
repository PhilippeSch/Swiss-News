import Foundation

class Settings: ObservableObject {
    @Published var cutoffHours: Double {
        didSet {
            UserDefaults.standard.set(cutoffHours, forKey: "cutoffHours")
            NotificationCenter.default.post(name: .settingsChanged, object: nil)
        }
    }
    
    init() {
        self.cutoffHours = UserDefaults.standard.double(forKey: "cutoffHours")
        if self.cutoffHours == 0 {
            self.cutoffHours = 48 // Default value
            UserDefaults.standard.set(self.cutoffHours, forKey: "cutoffHours")
        }
    }
}

extension Notification.Name {
    static let settingsChanged = Notification.Name("settingsChanged")
} 