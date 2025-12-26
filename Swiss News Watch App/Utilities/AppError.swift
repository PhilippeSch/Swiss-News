import Foundation

enum AppError: LocalizedError, Equatable {
    case networkError(String)
    case parsingError(String)
    case noData
    case invalidURL(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let details):
            return String(localized: "Keine Internetverbindung: \(details)")
        case .parsingError(let details):
            return String(localized: "Fehler beim Laden der Daten: \(details)")
        case .noData:
            return String(localized: "Keine Artikel verfügbar")
        case .invalidURL(let url):
            return String(localized: "Ungültige URL: \(url)")
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return String(localized: "Bitte überprüfe deine Internetverbindung und versuche es erneut.")
        case .parsingError, .invalidURL:
            return String(localized: "Bitte versuche es später erneut.")
        case .noData:
            return String(localized: "Versuche die Filtereinstellungen anzupassen.")
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let l), .networkError(let r)): return l == r
        case (.parsingError(let l), .parsingError(let r)): return l == r
        case (.noData, .noData): return true
        case (.invalidURL(let l), .invalidURL(let r)): return l == r
        default: return false
        }
    }
} 