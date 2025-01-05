import Foundation

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded(Date)
    case error(AppError)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var error: AppError? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
    
    var lastUpdate: Date? {
        if case .loaded(let date) = self {
            return date
        }
        return nil
    }
} 