import XCTest
import CoreGraphics
import ImageIO
import UIKit
@testable import Swiss_News_Watch_App

final class ArticleImageLoaderTests: XCTestCase {
    override func setUp() {
        super.setUp()
        StubURLProtocol.reset()
        ImageCache.shared.removeAll()
    }

    override func tearDown() {
        StubURLProtocol.reset()
        ImageCache.shared.removeAll()
        super.tearDown()
    }

    // MARK: - Downsampling

    func testDownsamplingShrinksAnOversizedImage() throws {
        let data = try XCTUnwrap(makeJPEG(width: 2000, height: 1500))

        let image = try XCTUnwrap(ArticleImageLoader.downsample(data, maxPixelSize: 400))

        let longestSide = max(image.size.width, image.size.height)
        XCTAssertEqual(longestSide, 400, accuracy: 1, "Longest side should be capped at the requested size")
        XCTAssertEqual(image.size.width / image.size.height, 2000.0 / 1500.0, accuracy: 0.01, "Aspect ratio preserved")
    }

    func testDownsamplingLeavesSmallImagesAlone() throws {
        let data = try XCTUnwrap(makeJPEG(width: 120, height: 90))

        let image = try XCTUnwrap(ArticleImageLoader.downsample(data, maxPixelSize: 400))

        XCTAssertEqual(max(image.size.width, image.size.height), 120, accuracy: 1)
    }

    func testDownsamplingRejectsGarbage() {
        let notAnImage = Data("nope".utf8)

        XCTAssertNil(ArticleImageLoader.downsample(notAnImage, maxPixelSize: 400))
    }

    // MARK: - Loading

    func testLoadDownsamplesWhatItDownloads() async throws {
        let data = try XCTUnwrap(makeJPEG(width: 1600, height: 1200))
        StubURLProtocol.responder = { _ in (200, data) }
        let url = try XCTUnwrap(URL(string: "https://cdn.test/gross.jpg"))

        let image = try await ArticleImageLoader.load(url, using: StubURLProtocol.makeSession())

        XCTAssertEqual(max(image.size.width, image.size.height), ArticleImageLoader.maxPixelSize, accuracy: 1)
    }

    func testLoadThrowsOnHTTPError() async throws {
        StubURLProtocol.responder = { _ in (404, Data()) }
        let url = try XCTUnwrap(URL(string: "https://cdn.test/fehlt.jpg"))

        do {
            _ = try await ArticleImageLoader.load(url, using: StubURLProtocol.makeSession())
            XCTFail("Expected a failure for a 404")
        } catch {
            // expected
        }
    }

    func testLoadThrowsOnUndecodableBody() async throws {
        StubURLProtocol.responder = { _ in (200, Data("not an image".utf8)) }
        let url = try XCTUnwrap(URL(string: "https://cdn.test/kaputt.jpg"))

        do {
            _ = try await ArticleImageLoader.load(url, using: StubURLProtocol.makeSession())
            XCTFail("Expected a failure for an undecodable body")
        } catch {
            // expected
        }
    }

    // MARK: - Caching

    func testCacheRoundTrip() throws {
        let data = try XCTUnwrap(makeJPEG(width: 200, height: 200))
        let image = try XCTUnwrap(ArticleImageLoader.downsample(data, maxPixelSize: 400))
        let url = try XCTUnwrap(URL(string: "https://cdn.test/bild.jpg"))
        let key = ArticleImageLoader.cacheKey(for: url)

        XCTAssertNil(ImageCache.shared.image(forKey: key))
        ImageCache.shared.insert(image, forKey: key)

        XCTAssertNotNil(ImageCache.shared.image(forKey: key), "A revisited row should hit the cache")
    }

    func testCacheKeysDifferPerURL() throws {
        let first = try XCTUnwrap(URL(string: "https://cdn.test/eins.jpg"))
        let second = try XCTUnwrap(URL(string: "https://cdn.test/zwei.jpg"))

        XCTAssertNotEqual(ArticleImageLoader.cacheKey(for: first), ArticleImageLoader.cacheKey(for: second))
    }

    func testSecondLoadOfSameURLCanBeServedFromCacheWithoutRefetching() async throws {
        let data = try XCTUnwrap(makeJPEG(width: 800, height: 600))
        StubURLProtocol.responder = { _ in (200, data) }
        let url = try XCTUnwrap(URL(string: "https://cdn.test/einmal.jpg"))
        let key = ArticleImageLoader.cacheKey(for: url)

        let image = try await ArticleImageLoader.load(url, using: StubURLProtocol.makeSession())
        ImageCache.shared.insert(image, forKey: key)
        XCTAssertEqual(StubURLProtocol.requestedURLs.count, 1)

        // What the view does on the second appearance.
        XCTAssertNotNil(ImageCache.shared.image(forKey: key))
        XCTAssertEqual(StubURLProtocol.requestedURLs.count, 1, "Cache hit should not issue another request")
    }

    // MARK: - Helpers

    /// UIGraphicsImageRenderer is unavailable on watchOS, so build the fixture
    /// with Core Graphics and encode it with ImageIO.
    private func makeJPEG(width: Int, height: Int) -> Data? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return nil }

        context.setFillColor(CGColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.setFillColor(CGColor(red: 0.2, green: 0.3, blue: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height / 2))

        guard let cgImage = context.makeImage() else { return nil }

        let encoded = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            encoded, "public.jpeg" as CFString, 1, nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return encoded as Data
    }
}
