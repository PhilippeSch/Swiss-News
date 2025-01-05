import Foundation

struct NewsCategory: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let feedURL: String
    let group: CategoryGroup
    
    enum CategoryGroup: String, Codable, Identifiable, CaseIterable {
        case news
        case sport
        case knowledge
        case culture
        
        var id: String { self.rawValue }
        
        var sortOrder: Int {
            switch self {
            case .news: return 0
            case .sport: return 1
            case .knowledge: return 2
            case .culture: return 3
            }
        }
    }
    
    static let available: [NewsCategory] = [
        // News Group
        NewsCategory(id: "news_all", title: "News", feedURL: "https://www.srf.ch/news/bnf/rss/1646", group: .news),
        NewsCategory(id: "news_latest", title: "Das Neueste", feedURL: "https://www.srf.ch/news/bnf/rss/19032223", group: .news),
        NewsCategory(id: "news_swiss", title: "Schweiz", feedURL: "https://www.srf.ch/news/bnf/rss/1890", group: .news),
        NewsCategory(id: "news_international", title: "International", feedURL: "https://www.srf.ch/news/bnf/rss/1922", group: .news),
        NewsCategory(id: "news_economy", title: "Wirtschaft", feedURL: "https://www.srf.ch/news/bnf/rss/1926", group: .news),
        
        // Sport Group
        NewsCategory(id: "sport_all", title: "Sport", feedURL: "https://www.srf.ch/sport/bnf/rss/718", group: .sport),
        NewsCategory(id: "sport_football", title: "Fussball", feedURL: "https://www.srf.ch//sport/bnf/rss/2562", group: .sport),
        NewsCategory(id: "sport_hockey", title: "Eishockey", feedURL: "https://www.srf.ch/sport/bnf/rss/3418", group: .sport),
        NewsCategory(id: "sport_tennis", title: "Tennis", feedURL: "https://www.srf.ch/sport/bnf/rss/2814", group: .sport),
        NewsCategory(id: "sport_ski", title: "Ski Alpin", feedURL: "https://www.srf.ch/sport/bnf/rss/787950", group: .sport),
        NewsCategory(id: "sport_athletics", title: "Leichtathletik", feedURL: "https://www.srf.ch/sport/bnf/rss/3042", group: .sport),
        NewsCategory(id: "sport_motorsport", title: "Motorsport", feedURL: "https://www.srf.ch/sport/bnf/rss/2958", group: .sport),
        NewsCategory(id: "sport_more", title: "Mehr Sport", feedURL: "https://www.srf.ch/sport/bnf/rss/3010", group: .sport),
        
        // Culture Group
        NewsCategory(id: "culture_all", title: "Kultur", feedURL: "https://www.srf.ch/kultur/bnf/rss/454", group: .culture),
        NewsCategory(id: "culture_film", title: "Film & Serien", feedURL: "https://www.srf.ch/kultur/bnf/rss/8726", group: .culture),
        NewsCategory(id: "culture_society", title: "Gesellschaft & Religion", feedURL: "https://www.srf.ch/kultur/bnf/rss/8798", group: .culture),
        NewsCategory(id: "culture_literature", title: "Literatur", feedURL: "https://www.srf.ch/kultur/bnf/rss/8762", group: .culture),
        NewsCategory(id: "culture_music", title: "Musik", feedURL: "https://www.srf.ch/kultur/bnf/rss/8738", group: .culture),
        NewsCategory(id: "culture_art", title: "Kunst", feedURL: "https://www.srf.ch/kultur/bnf/rss/8774", group: .culture),
        NewsCategory(id: "culture_stage", title: "Bühne", feedURL: "https://www.srf.ch/kultur/bnf/rss/8786", group: .culture),
        
        // Knowledge Group
        NewsCategory(id: "knowledge_all", title: "Wissen", feedURL: "https://www.srf.ch/bnf/rss/630", group: .knowledge),
        NewsCategory(id: "knowledge_health", title: "Gesundheit", feedURL: "https://www.srf.ch/bnf/rss/19919909", group: .knowledge),
        NewsCategory(id: "knowledge_sustainability", title: "Nachhaltigkeit", feedURL: "https://www.srf.ch/bnf/rss/19920002", group: .knowledge),
        NewsCategory(id: "knowledge_human", title: "Mensch", feedURL: "https://www.srf.ch/bnf/rss/19920107", group: .knowledge),
        NewsCategory(id: "knowledge_nature", title: "Natur & Tiere", feedURL: "https://www.srf.ch/bnf/rss/19920818", group: .knowledge),
        NewsCategory(id: "knowledge_tech", title: "Technik", feedURL: "https://www.srf.ch/bnf/rss/19920122", group: .knowledge)
    ]
    
    static let defaultCategories: Set<String> = Set([
        "news_all",        // News
        "sport_all",       // Sport
        "culture_all",     // Kultur
        "knowledge_all"    // Wissen
    ])
    
    static func categoriesByGroup() -> [CategoryGroup: [NewsCategory]] {
        Dictionary(grouping: available, by: { $0.group })
    }
} 