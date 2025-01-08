import Foundation

enum LoadingState: Equatable {
    case idle
    case loading(lastUpdate: Date?)
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
        switch self {
        case .idle:
            return nil
        case .loading(let date):
            return date
        case .loaded(let date):
            return date
        case .error:
            return nil
        }
    }
} 