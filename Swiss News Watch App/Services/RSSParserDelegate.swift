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
    
    private func extractImageFromDescription(_ description: String) -> String? {
        let pattern = "<img[^>]+src=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: description, range: NSRange(description.startIndex..., in: description)),
              let range = Range(match.range(at: 1), in: description) else {
            return nil
        }
        return String(description[range])
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            
            let pubDate = dateFormatter.date(from: currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines)) ?? Date()
            
            var finalDescription = currentDescription
            
            if let descriptionImageUrl = extractImageFromDescription(currentDescription) {
                finalDescription += "<enclosure url=\"\(descriptionImageUrl)\" type=\"image/jpeg\"/>"
            } else if !currentMediaContent.isEmpty {
                finalDescription += "<enclosure url=\"\(currentMediaContent)\" type=\"image/jpeg\"/>"
            } else if !currentMediaThumbnail.isEmpty {
                finalDescription += "<enclosure url=\"\(currentMediaThumbnail)\" type=\"image/jpeg\"/>"
            } else if !currentEnclosureUrl.isEmpty {
                finalDescription += "<enclosure url=\"\(currentEnclosureUrl)\" type=\"image/jpeg\"/>"
            }
            
            let newsItem = NewsItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: finalDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: pubDate,
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                guid: currentGuid.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            newsItems.append(newsItem)
            parsingItem = false
        }
    }
} 