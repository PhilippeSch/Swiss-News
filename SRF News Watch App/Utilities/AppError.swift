import Foundation

enum AppError: LocalizedError {
    case networkError(String)
    case parsingError(String)
    case noData
    case invalidURL(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let details):
            return "Keine Internetverbindung: \(details)"
        case .parsingError(let details):
            return "Fehler beim Laden der Daten: \(details)"
        case .noData:
            return "Keine Artikel verfügbar"
        case .invalidURL(let url):
            return "Ungültige URL: \(url)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Bitte überprüfe deine Internetverbindung und versuche es erneut."
        case .parsingError, .invalidURL:
            return "Bitte versuche es später erneut."
        case .noData:
            return "Versuche die Filtereinstellungen anzupassen."
        }
    }
} 