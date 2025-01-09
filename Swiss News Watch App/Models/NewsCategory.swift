import Foundation

struct NewsCategory: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let feedURL: String
    let group: CategoryGroup
    let sourceId: String
    
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
        
        var title: String {
            switch self {
            case .news: return "News"
            case .sport: return "Sport"
            case .culture: return "Kultur"
            case .knowledge: return "Wissen"
            }
        }
    }

    
    static let available: [NewsCategory] = [
        // SRF News Group
        NewsCategory(id: "srf_news_all", title: "News", feedURL: "https://www.srf.ch/news/bnf/rss/1646", group: .news, sourceId: "srf"),
        NewsCategory(id: "srf_news_latest", title: "Das Neueste", feedURL: "https://www.srf.ch/news/bnf/rss/19032223", group: .news, sourceId: "srf"),
        NewsCategory(id: "srf_news_swiss", title: "Schweiz", feedURL: "https://www.srf.ch/news/bnf/rss/1890", group: .news, sourceId: "srf"),
        NewsCategory(id: "srf_news_international", title: "International", feedURL: "https://www.srf.ch/news/bnf/rss/1922", group: .news, sourceId: "srf"),
        NewsCategory(id: "srf_news_economy", title: "Wirtschaft", feedURL: "https://www.srf.ch/news/bnf/rss/1926", group: .news, sourceId: "srf"),
        
        // SRF Sport Group
        NewsCategory(id: "srf_sport_all", title: "Sport", feedURL: "https://www.srf.ch/sport/bnf/rss/718", group: .sport, sourceId: "srf"),
        NewsCategory(id: "srf_sport_football", title: "Fussball", feedURL: "https://www.srf.ch//sport/bnf/rss/2562", group: .sport, sourceId: "srf"),
        NewsCategory(id: "srf_sport_hockey", title: "Eishockey", feedURL: "https://www.srf.ch/sport/bnf/rss/3418", group: .sport, sourceId: "srf"),
        NewsCategory(id: "srf_sport_tennis", title: "Tennis", feedURL: "https://www.srf.ch/sport/bnf/rss/2814", group: .sport, sourceId: "srf"),
        NewsCategory(id: "srf_sport_ski", title: "Ski Alpin", feedURL: "https://www.srf.ch/sport/bnf/rss/787950", group: .sport, sourceId: "srf"),
        NewsCategory(id: "srf_sport_athletics", title: "Leichtathletik", feedURL: "https://www.srf.ch/sport/bnf/rss/3042", group: .sport, sourceId: "srf"),
        NewsCategory(id: "srf_sport_motorsport", title: "Motorsport", feedURL: "https://www.srf.ch/sport/bnf/rss/2958", group: .sport, sourceId: "srf"),
        NewsCategory(id: "srf_sport_more", title: "Mehr Sport", feedURL: "https://www.srf.ch/sport/bnf/rss/3010", group: .sport, sourceId: "srf"),
        
        // SRF Culture Group
        NewsCategory(id: "srf_culture_all", title: "Kultur", feedURL: "https://www.srf.ch/kultur/bnf/rss/454", group: .culture, sourceId: "srf"),
        NewsCategory(id: "srf_culture_film", title: "Film & Serien", feedURL: "https://www.srf.ch/kultur/bnf/rss/8726", group: .culture, sourceId: "srf"),
        NewsCategory(id: "srf_culture_society", title: "Gesellschaft & Religion", feedURL: "https://www.srf.ch/kultur/bnf/rss/8798", group: .culture, sourceId: "srf"),
        NewsCategory(id: "srf_culture_literature", title: "Literatur", feedURL: "https://www.srf.ch/kultur/bnf/rss/8762", group: .culture, sourceId: "srf"),
        NewsCategory(id: "srf_culture_music", title: "Musik", feedURL: "https://www.srf.ch/kultur/bnf/rss/8738", group: .culture, sourceId: "srf"),
        NewsCategory(id: "srf_culture_art", title: "Kunst", feedURL: "https://www.srf.ch/kultur/bnf/rss/8774", group: .culture, sourceId: "srf"),
        NewsCategory(id: "srf_culture_stage", title: "Bühne", feedURL: "https://www.srf.ch/kultur/bnf/rss/8786", group: .culture, sourceId: "srf"),
        
        // SRF Knowledge Group
        NewsCategory(id: "srf_knowledge_all", title: "Wissen", feedURL: "https://www.srf.ch/bnf/rss/630", group: .knowledge, sourceId: "srf"),
        NewsCategory(id: "srf_knowledge_health", title: "Gesundheit", feedURL: "https://www.srf.ch/bnf/rss/19919909", group: .knowledge, sourceId: "srf"),
        NewsCategory(id: "srf_knowledge_sustainability", title: "Nachhaltigkeit", feedURL: "https://www.srf.ch/bnf/rss/19920002", group: .knowledge, sourceId: "srf"),
        NewsCategory(id: "srf_knowledge_human", title: "Mensch", feedURL: "https://www.srf.ch/bnf/rss/19920107", group: .knowledge, sourceId: "srf"),
        NewsCategory(id: "srf_knowledge_nature", title: "Natur & Tiere", feedURL: "https://www.srf.ch/bnf/rss/19920818", group: .knowledge, sourceId: "srf"),
        NewsCategory(id: "srf_knowledge_tech", title: "Technik", feedURL: "https://www.srf.ch/bnf/rss/19920122", group: .knowledge, sourceId: "srf"),
        
        // NZZ News Group
        NewsCategory(id: "nzz_news_recent", title: "Neuestes", feedURL: "https://www.nzz.ch/recent.rss", group: .news, sourceId: "nzz"),
        NewsCategory(id: "nzz_news_top", title: "Topthemen", feedURL: "https://www.nzz.ch/startseite.rss", group: .news, sourceId: "nzz"),
        NewsCategory(id: "nzz_news_international", title: "International", feedURL: "https://www.nzz.ch/international.rss", group: .news, sourceId: "nzz"),
        NewsCategory(id: "nzz_news_swiss", title: "Schweiz", feedURL: "https://www.nzz.ch/schweiz.rss", group: .news, sourceId: "nzz"),
        NewsCategory(id: "nzz_news_economy", title: "Wirtschaft", feedURL: "https://www.nzz.ch/wirtschaft.rss", group: .news, sourceId: "nzz"),
        NewsCategory(id: "nzz_news_finance", title: "Finanzen", feedURL: "https://www.nzz.ch/finanzen.rss", group: .news, sourceId: "nzz"),
        NewsCategory(id: "nzz_news_zurich", title: "Zürich", feedURL: "https://www.nzz.ch/zuerich.rss", group: .news, sourceId: "nzz"),
        NewsCategory(id: "nzz_news_panorama", title: "Panorama", feedURL: "https://www.nzz.ch/panorama.rss", group: .news, sourceId: "nzz"),
        
        // NZZ Sport Group
        NewsCategory(id: "nzz_sport_all", title: "Sport", feedURL: "https://www.nzz.ch/sport.rss", group: .sport, sourceId: "nzz"),
        
        // NZZ Knowledge Group
        NewsCategory(id: "nzz_knowledge_science", title: "Wissenschaft", feedURL: "https://www.nzz.ch/wissenschaft.rss", group: .knowledge, sourceId: "nzz"),
        NewsCategory(id: "nzz_knowledge_tech", title: "Technologie", feedURL: "https://www.nzz.ch/technologie.rss", group: .knowledge, sourceId: "nzz"),
        NewsCategory(id: "nzz_knowledge_auto", title: "Auto", feedURL: "https://www.nzz.ch/mobilitaet/auto-mobil.rss", group: .knowledge, sourceId: "nzz"),
        
        // NZZ Culture Group
        NewsCategory(id: "nzz_culture_all", title: "Feuilleton", feedURL: "https://www.nzz.ch/feuilleton.rss", group: .culture, sourceId: "nzz"),
        
        // 20 Minuten News Group
        NewsCategory(id: "20min_news_all", title: "News", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/front", group: .news, sourceId: "20min"),
        NewsCategory(id: "20min_news_swiss", title: "Schweiz", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/schweiz", group: .news, sourceId: "20min"),
        NewsCategory(id: "20min_news_international", title: "International", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/ausland", group: .news, sourceId: "20min"),
        NewsCategory(id: "20min_news_economy", title: "Wirtschaft", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/wirtschaft", group: .news, sourceId: "20min"),
        NewsCategory(id: "20min_news_digital", title: "Digital", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/digital", group: .news, sourceId: "20min"),
        
        // 20 Minuten Sport Group
        NewsCategory(id: "20min_sport_all", title: "Sport", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/sport", group: .sport, sourceId: "20min"),
        NewsCategory(id: "20min_sport_football", title: "Fussball", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/sport/fussball", group: .sport, sourceId: "20min"),
        NewsCategory(id: "20min_sport_hockey", title: "Eishockey", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/sport/eishockey", group: .sport, sourceId: "20min"),
        NewsCategory(id: "20min_sport_winter", title: "Wintersport", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/sport/wintersport", group: .sport, sourceId: "20min"),
        NewsCategory(id: "20min_sport_tennis", title: "Tennis", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/sport/tennis", group: .sport, sourceId: "20min"),
        NewsCategory(id: "20min_sport_motorsport", title: "Motorsport", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/sport/motorsport", group: .sport, sourceId: "20min"),
        NewsCategory(id: "20min_sport_more", title: "Weitere Sportarten", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/sport/weitere-sportarten", group: .sport, sourceId: "20min"),
        
        // 20 Minuten Knowledge Group
        NewsCategory(id: "20min_knowledge_all", title: "Wissen", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/wissen", group: .knowledge, sourceId: "20min"),
        NewsCategory(id: "20min_knowledge_health", title: "Gesundheit", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/gesundheit", group: .knowledge, sourceId: "20min"),
        
        // 20 Minuten Culture Group
        NewsCategory(id: "20min_culture_people", title: "People", feedURL: "https://partner-feeds.beta.20min.ch/rss/20minuten/people", group: .culture, sourceId: "20min")
    ]
    
    static let defaultCategories: Set<String> = Set([
        "srf_news_all",
        "srf_sport_all",
        "srf_culture_all",
        "srf_knowledge_all",
        "nzz_news_all",
        "nzz_sport_all",
        "nzz_culture_all",
        "20min_news_all",
        "20min_sport_all",
        "20min_knowledge_all"
    ])
    
    static func categoriesByGroup() -> [CategoryGroup: [NewsCategory]] {
        Dictionary(grouping: available, by: { $0.group })
    }
} 
