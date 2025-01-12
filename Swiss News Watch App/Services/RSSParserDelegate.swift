import Foundation

class RSSParserDelegate: NSObject, XMLParserDelegate {
    private(set) var newsItems: [NewsItem] = []
    private var currentItem: NewsItemBuilder?
    private var currentElement = ""
    private var currentValue = ""
    
    private struct NewsItemBuilder {
        var title = ""
        var description = ""
        var pubDate = Date()
        var link = ""
        var guid = ""
        var imageUrl: URL?
        
        func build() -> NewsItem {
            NewsItem(
                title: title,
                description: description,
                pubDate: pubDate,
                link: link,
                guid: guid,
                imageUrl: imageUrl
            )
        }
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        switch elementName {
        case "item":
            currentItem = NewsItemBuilder()
        case "media:content", "enclosure":
            if let urlString = attributeDict["url"], let url = URL(string: urlString) {
                currentItem?.imageUrl = url
            }
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard var item = currentItem else { return }
        
        let value = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch elementName {
        case "title":
            item.title = value
        case "description", "content:encoded":
            if item.description.isEmpty {
                item.description = value
            }
        case "pubDate":
            if let date = DateFormatter.rssDateFormatter.date(from: value) {
                item.pubDate = date
            }
        case "link":
            item.link = value
        case "guid":
            item.guid = value
        case "item":
            currentItem = nil
            newsItems.append(item.build())
        default:
            break
        }
        
        currentValue = ""
        currentItem = item
    }
}

private extension DateFormatter {
    static let rssDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()
} 