import Foundation

final class RSSParserDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentPubDate = ""
    private var currentLink = ""
    private var currentGuid = ""
    private var currentEnclosureUrl = ""
    private var currentMediaThumbnail = ""
    private var currentMediaContent = ""
    private var parsingItem = false
    
    var newsItems: [NewsItem] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "item" {
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentGuid = ""
            currentEnclosureUrl = ""
            currentMediaThumbnail = ""
            currentMediaContent = ""
            parsingItem = true
        } else if elementName == "enclosure" {
            currentEnclosureUrl = attributeDict["url"] ?? ""
        } else if elementName == "media:thumbnail" {
            currentMediaThumbnail = attributeDict["url"] ?? ""
        } else if elementName == "media:content" {
            if let url = attributeDict["url"], 
               let type = attributeDict["type"], 
               type.starts(with: "image/") {
                currentMediaContent = url
            }
        }
        currentElement = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if parsingItem {
            switch currentElement {
            case "title": currentTitle += string
            case "description": currentDescription += string
            case "pubDate": currentPubDate += string
            case "link": currentLink += string
            case "guid": currentGuid += string
            default: break
            }
        }
    }
    
    /// RFC-822 dates as used by every feed we consume. Reused across items —
    /// `DateFormatter` is expensive to create and parsing runs on a single
    /// thread per `XMLParser` run.
    private static let pubDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()

    private static let imageTagRegex = try! NSRegularExpression(pattern: "<img[^>]+src=\"([^\"]+)\"")

    private func extractImageFromDescription(_ description: String) -> String? {
        let range = NSRange(description.startIndex..., in: description)
        guard let match = Self.imageTagRegex.firstMatch(in: description, range: range),
              let matchRange = Range(match.range(at: 1), in: description) else {
            return nil
        }
        return String(description[matchRange])
    }

    /// First image reference found for the current item, in order of preference.
    private var currentImageUrl: URL? {
        let candidate = extractImageFromDescription(currentDescription)
            ?? [currentMediaContent, currentMediaThumbnail, currentEnclosureUrl].first { !$0.isEmpty }
        return candidate.flatMap(URL.init(string:))
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let pubDate = Self.pubDateFormatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Date()

            let newsItem = NewsItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: pubDate,
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                guid: currentGuid.trimmingCharacters(in: .whitespacesAndNewlines),
                imageUrl: currentImageUrl
            )
            newsItems.append(newsItem)
            parsingItem = false
        }
    }
} 