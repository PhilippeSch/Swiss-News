struct ArticleResponse: Codable {
    let results: [Article]
    let cursor: String?
}

struct Article: Codable {
    let id: String
    let publisher: String
    let content: ArticleContent?
    let title: [LocalizedText]?
    let lead: [LocalizedText]?
    let modificationDate: String?
    let releaseDate: String?
}

struct ArticleContent: Codable {
    let text: [String]
}

struct LocalizedText: Codable {
    let content: String
    let language: String?
} 