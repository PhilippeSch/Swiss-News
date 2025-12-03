import SwiftUI
import SwiftSoup

struct ArticleView: View {
    let title: String
    let url: String
    @State private var articleContent: String = ""
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss
    @State private var hasSubtitle = false
    @State private var subtitles: Set<String> = []
    @Binding var isPresented: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .padding(.bottom, 4)
                
                if isLoading {
                    VStack {
                        ProgressView("Wird aktualisiert...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                } else if let error = error {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Error:")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                } else {
                    HyphenatedTextView(text: articleContent, subtitles: subtitles)
                        .padding(.horizontal, 4)
                }
                
                if !isLoading {
                    Button("Zurück") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
            }
            .padding()
        }
        .accessibilityIdentifier("articleDetailView")
        .navigationTitle("Artikel")
        .interactiveDismissDisabled(isLoading)
        .task {
            await loadContent()
        }
    }
    
    private func loadContent() async {
        isLoading = true
        
        do {
            try await fetchArticleContent()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    private func fetchArticleContent() async throws {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("Mozilla/5.0 (watchOS) SwissNewsApp/1.0", forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let document = try SwiftSoup.parse(html)
        var content = ""
        
        if url.absoluteString.contains("nzz.ch") {
            subtitles.removeAll()
            
            var paragraphCount = 0
            var subtitleCount = 0
            var foundContent = false
            
            // Neue Struktur: Direkte Suche nach componenttype="p" und componenttype="subtitle"
            let newStructureElements = try document.select("[componenttype='p'], [componenttype='subtitle']")
            if !newStructureElements.isEmpty() {
                print("DEBUG: Neue NZZ-Struktur gefunden - \(newStructureElements.count) Elemente")
                for element in newStructureElements {
                    let componentType = try element.attr("componenttype")
                    let elementText = try element.text()
                    
                    if !elementText.isEmpty {
                        switch componentType {
                        case "subtitle":
                            content += "\(elementText)\n\n"
                            subtitles.insert(elementText)
                            subtitleCount += 1
                        case "p":
                            content += "\(elementText)\n\n"
                            paragraphCount += 1
                        default:
                            break
                        }
                    }
                }
                foundContent = true
                print("DEBUG: Neue Struktur - \(paragraphCount) Absätze, \(subtitleCount) Untertitel gefunden")
            }
            
            // Fallback 1: Alte Struktur [pagetype='Article']
            if !foundContent {
                print("DEBUG: Fallback zu alter Struktur [pagetype='Article']")
                let articleElements = try document.select("[pagetype='Article']")
                if !articleElements.isEmpty() {
                    for element in articleElements {
                        let componentType = try element.attr("componenttype")
                        let elementText = try element.text()
                        
                        if !elementText.isEmpty {
                            switch componentType {
                            case "subtitle":
                                content += "\(elementText)\n\n"
                                subtitles.insert(elementText)
                                subtitleCount += 1
                            case "p":
                                content += "\(elementText)\n\n"
                                paragraphCount += 1
                            default:
                                break
                            }
                        }
                    }
                    foundContent = true
                    print("DEBUG: Alte Struktur - \(paragraphCount) Absätze, \(subtitleCount) Untertitel gefunden")
                }
            }
            
            // Fallback 2: Klasse .articlecomponent
            if !foundContent {
                print("DEBUG: Fallback zu .articlecomponent")
                let articleComponents = try document.select(".articlecomponent")
                if !articleComponents.isEmpty() {
                    for element in articleComponents {
                        let componentType = try element.attr("componenttype")
                        let elementText = try element.text()
                        
                        if !elementText.isEmpty {
                            switch componentType {
                            case "subtitle":
                                content += "\(elementText)\n\n"
                                subtitles.insert(elementText)
                                subtitleCount += 1
                            case "p":
                                content += "\(elementText)\n\n"
                                paragraphCount += 1
                            default:
                                break
                            }
                        }
                    }
                    foundContent = true
                    print("DEBUG: .articlecomponent - \(paragraphCount) Absätze, \(subtitleCount) Untertitel gefunden")
                }
            }
            
            if !foundContent {
                print("DEBUG: Keine NZZ-Artikel-Inhalte gefunden")
                throw URLError(.cannotParseResponse)
            }
            
            print("DEBUG: Final - \(paragraphCount) Absätze, \(subtitleCount) Untertitel")
        } else {
            subtitles.removeAll()
            let possibleSelectors = [
                "section.articlepage__article-content",
                "div.article-content",
                "article",
                ".article__body"
            ]
            
            var foundContent = false
            for selector in possibleSelectors {
                if let articleSection = try document.select(selector).first() {
                    let lists = try articleSection.select("ul")
                    let paragraphs = try articleSection.select("p")
                    
                    for list in lists {
                        let items = try list.select("li")
                        for item in items {
                            let itemText = try item.text()
                            content += "• \(itemText)\n"
                        }
                        content += "\n"
                    }
                    
                    for paragraph in paragraphs {
                        let paragraphText = try paragraph.text()
                        if !paragraphText.isEmpty {
                            content += "\(paragraphText)\n\n"
                        }
                    }
                    
                    foundContent = true
                    break
                }
            }
            
            if !foundContent {
                throw URLError(.cannotParseResponse)
            }
        }
        
        let cleanedContent = content.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        articleContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if articleContent.isEmpty {
            throw URLError(.zeroByteResource)
        }
    }
} 
