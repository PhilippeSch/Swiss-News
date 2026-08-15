import Foundation

/// The session everything networking should go through, so UI tests can serve
/// canned responses instead of reaching the network.
enum AppURLSession {
    static var `default`: URLSession {
        #if DEBUG
        UITestSupport.isActive ? UITestSupport.makeSession() : .shared
        #else
        .shared
        #endif
    }
}
