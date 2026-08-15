import Foundation

/// Persists the last fetched articles so a relaunch can render immediately
/// instead of showing an empty list until the network answers.
///
/// An actor so the disk I/O stays off the main actor.
actor NewsCacheStore {
    struct Snapshot: Codable, Sendable {
        let itemsByCategory: [String: [NewsItem]]
        let savedAt: Date
    }

    private let fileURL: URL

    init(fileName: String = "news-cache.json", directory: FileManager.SearchPathDirectory = .cachesDirectory) {
        let base = FileManager.default.urls(for: directory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = base.appendingPathComponent(fileName)
    }

    func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    func save(itemsByCategory: [String: [NewsItem]], savedAt: Date = Date()) {
        let snapshot = Snapshot(itemsByCategory: itemsByCategory, savedAt: savedAt)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
