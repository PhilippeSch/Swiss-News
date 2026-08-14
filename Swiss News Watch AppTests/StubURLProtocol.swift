import Foundation

/// Intercepts every request made through a session configured with it, so feed
/// tests are deterministic and never touch the network.
final class StubURLProtocol: URLProtocol {
    /// Answers a request with a status code and body. Set before each test.
    nonisolated(unsafe) static var responder: ((URLRequest) -> (status: Int, body: Data))?

    /// Artificial latency per request, to observe overlapping fetches.
    nonisolated(unsafe) static var responseDelay: TimeInterval = 0

    /// Every URL that was requested, in order.
    nonisolated(unsafe) private(set) static var requestedURLs: [URL] = []

    /// High-water mark of simultaneously in-flight requests.
    nonisolated(unsafe) private(set) static var maxConcurrentRequests = 0

    nonisolated(unsafe) private static var inFlight = 0
    private static let lock = NSLock()

    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        responder = nil
        responseDelay = 0
        requestedURLs = []
        maxConcurrentRequests = 0
        inFlight = 0
    }

    static func record(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        requestedURLs.append(url)
    }

    private static func beginRequest() {
        lock.lock()
        defer { lock.unlock() }
        inFlight += 1
        maxConcurrentRequests = max(maxConcurrentRequests, inFlight)
    }

    private static func endRequest() {
        lock.lock()
        defer { lock.unlock() }
        inFlight -= 1
    }

    /// A session that routes all traffic through this stub. The per-host
    /// connection limit is raised so tests measure the app's own concurrency
    /// cap rather than URLSession's.
    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        configuration.httpMaximumConnectionsPerHost = 20
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
        Self.beginRequest()

        let delay = Self.responseDelay
        let responder = Self.responder
        let request = self.request

        // Answer off the protocol queue: blocking here would serialise every
        // request and make concurrent fetching look sequential.
        let work: () -> Void = { [weak self] in
            guard let self else { return }
            defer { Self.endRequest() }

            let (status, body) = responder?(request) ?? (200, Data())
            guard !self.isCancelled else { return }

            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: body)
            self.client?.urlProtocolDidFinishLoading(self)
        }

        if delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
        } else {
            DispatchQueue.global().async(execute: work)
        }
    }

    private let cancelLock = NSLock()
    private var _isCancelled = false
    private var isCancelled: Bool {
        cancelLock.lock()
        defer { cancelLock.unlock() }
        return _isCancelled
    }

    override func stopLoading() {
        cancelLock.lock()
        _isCancelled = true
        cancelLock.unlock()
    }
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
