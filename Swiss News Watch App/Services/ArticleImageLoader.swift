import Foundation
import ImageIO
import UIKit

/// In-memory store of decoded, downsampled article images, so scrolling back to
/// a row neither re-downloads nor re-decodes its image.
///
/// `NSCache` is thread-safe and evicts under memory pressure, which matters far
/// more on a watch than holding onto every image.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    init(countLimit: Int = 80, totalCostLimit: Int = 12 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString, cost: image.approximateBytes)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}

private extension UIImage {
    /// Rough decoded size, used as the cache cost.
    var approximateBytes: Int {
        guard let cgImage else { return 0 }
        return cgImage.height * cgImage.bytesPerRow
    }
}

enum ArticleImageLoader {
    /// Article images display at most ~200pt tall on the widest watch; 400px
    /// covers that at 2x without decoding full-resolution press photos.
    static let maxPixelSize: CGFloat = 400

    enum LoadError: Error {
        case badResponse
        case undecodable
    }

    static func cacheKey(for url: URL) -> String {
        "\(url.absoluteString)|\(Int(maxPixelSize))"
    }

    static var defaultSession: URLSession {
        #if DEBUG
        UITestSupport.isActive ? UITestSupport.makeSession() : .shared
        #else
        .shared
        #endif
    }

    /// Downloads and downsamples in one step. Not actor-isolated, so the decode
    /// stays off the main actor.
    static func load(_ url: URL, using session: URLSession? = nil) async throws -> UIImage {
        let (data, response) = try await (session ?? defaultSession).data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw LoadError.badResponse
        }

        guard let image = downsample(data, maxPixelSize: maxPixelSize) else {
            throw LoadError.undecodable
        }
        return image
    }

    /// Decodes straight to display size via ImageIO, so a 2000px press photo
    /// never becomes a full-size bitmap in memory.
    static func downsample(_ data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            return nil
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }
        return UIImage(cgImage: thumbnail)
    }
}
