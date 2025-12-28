import Foundation

struct NewsSource: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let logoName: String
    let order: Int
    
    static let available: [NewsSource] = [
        NewsSource(id: "srf", name: "SRF", logoName: "srf_logo", order: 1),
        NewsSource(id: "nzz", name: "NZZ", logoName: "nzz_logo", order: 2),
        NewsSource(id: "20min", name: "20 Minuten", logoName: "20min_logo", order: 3),
        NewsSource(id: "24heures", name: "24 Heures", logoName: "24heures_logo", order: 4),
        NewsSource(id: "rsi", name: "RSI", logoName: "rsi_logo", order: 5)
    ]
    
    static let defaultSources: Set<String> = Set([
        "srf",
        "nzz",
        "20min",
        "rsi",
        "24heures"
    ])
} 
