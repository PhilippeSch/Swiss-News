import Foundation

struct NewsSource: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logoName: String
    let order: Int
    
    static let available: [NewsSource] = [
        NewsSource(id: "srf", name: "SRF", logoName: "srf_logo", order: 1),
        NewsSource(id: "20min", name: "20 Minuten", logoName: "20min_logo", order: 2)
    ]
    
    static let defaultSources: Set<String> = Set([
        "srf",
        "20min"
    ])
} 