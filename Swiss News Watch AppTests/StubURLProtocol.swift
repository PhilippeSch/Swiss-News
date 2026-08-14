import Foundation

/// Intercepts every request made through a session configured with it, so feed
/// tests are deterministic and never touch the network.
final class StubURLProtocol: URLProtocol {
    /// Answers a request with a status code and body. Set before each test.
    nonisolated(unsafe) static var responder: ((URLRequest) -> (status: Int, body: Data))?

    /// Every URL that was requested, in order.
    nonisolated(unsafe) private(set) static var requestedURLs: [URL] = []

    private static let lock = NSLock()

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        responder = nil
        requestedURLs = []
    }

    static func record(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        requestedURLs.append(url)
    }

    /// A session that routes all traffic through this stub.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        Self.record(url)

        let (status, body) = Self.responder?(request) ?? (200, Data())
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

enum FeedFixture {
    private static let rfc822: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    /// A minimal well-formed feed whose items are recent enough to survive the
    /// cutoff filter.
    static func feed(itemCount: Int = 2, publishedAt date: Date = Date()) -> Data {
        let items = (1...itemCount).map { index in
            """
            <item>
                <title>Artikel \(index)</title>
                <description>Beschreibung \(index)</description>
                <pubDate>\(rfc822.string(from: date))</pubDate>
                <link>https://test.ch/artikel/\(index)</link>
                <guid>guid-\(index)</guid>
            </item>
            """
        }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:media="http://search.yahoo.com/mrss/">
            <channel>
        \(items)
            </channel>
        </rss>
        """.data(using: .utf8)!
    }
}
