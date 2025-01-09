import SwiftUI
import SwiftSoup

struct ArticleView: View {
    let title: String
    let url: String
    @State private var articleContent: String = "Loading..."
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss  // Für kontrolliertes Schließen
    
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
                        Text(articleContent)
                            .opacity(0.5)
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
                    HyphenatedTextView(text: articleContent)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Artikel")
        .interactiveDismissDisabled(isLoading)  // Verhindert Schließen während des Ladens
        .onAppear {
            print("🟢 ArticleView appeared")
        }
        .onDisappear {
            print("🔴 ArticleView disappeared")
        }
        .task {
            print("🟡 Starting content fetch task")
            do {
                await fetchArticleContent()
            } catch {
                print("❌ Task error: \(error)")
            }
            print("🟡 Finished content fetch task")
        }
    }
    
    private func fetchArticleContent() async {
        print("📥 Starting fetchArticleContent")
        do {
            print("🔍 Loading URL: \(url)")
            guard let url = URL(string: url) else {
                print("❌ Invalid URL")
                throw URLError(.badURL)
            }
            
            print("📡 Fetching data...")
            let (data, _) = try await URLSession.shared.data(from: url)
            print("✅ Data received: \(data.count) bytes")
            
            guard let html = String(data: data, encoding: .utf8) else {
                print("❌ Failed to decode HTML")
                throw URLError(.cannotDecodeContentData)
            }
            
            print("🔍 Parsing HTML...")
            let document = try SwiftSoup.parse(html)
            var content = ""
            
            // Zuerst versuchen wir NZZ-spezifische Elemente zu finden
            if url.absoluteString.contains("nzz.ch") {
                let articleElements = try document.select("[pagetype='Article']")
                for element in articleElements {
                    let componentType = try element.attr("componenttype")
                    let elementText = try element.text()
                    
                    if !elementText.isEmpty {
                        switch componentType {
                        case "subtitle":
                            content += "**\(elementText)**\n\n"
                        case "p":
                            content += "\(elementText)\n\n"
                        default:
                            break
                        }
                    }
                }
            }
            
            // Wenn kein NZZ-Content gefunden wurde, versuche die bewährten Selektoren
            if content.isEmpty {
                let possibleSelectors = [
                    "section.articlepage__article-content",  // SRF Selector
                    "div.article-content",                   // Möglicher 20min Selector
                    "article",                               // Generischer Artikel Selector
                    ".article__body"                         // Alternativer 20min Selector
                ]
                
                print("🔍 Trying selectors...")
                for selector in possibleSelectors {
                    print("  👉 Trying: \(selector)")
                    if let articleSection = try document.select(selector).first() {
                        print("  ✅ Found content with: \(selector)")
                        
                        // Handle bullet point lists
                        let lists = try articleSection.select("ul")
                        let paragraphs = try articleSection.select("p")
                        print("  📝 Found \(lists.size()) lists and \(paragraphs.size()) paragraphs")
                        
                        for list in lists {
                            let items = try list.select("li")
                            for item in items {
                                let itemText = try item.text()
                                content += "• \(itemText)\n"
                            }
                            content += "\n"
                        }
                        
                        // Handle paragraphs
                        for paragraph in paragraphs {
                            let paragraphText = try paragraph.text()
                            if !paragraphText.isEmpty {
                                content += "\(paragraphText)\n\n"
                            }
                        }
                        
                        break // Beende die Suche, wenn Content gefunden wurde
                    }
                }
            }
            
            print("📝 Content length before cleaning: \(content.count)")
            let cleanedContent = content.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            articleContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 Final content length: \(articleContent.count)")
            
            if articleContent.isEmpty {
                print("⚠️ No content found")
                articleContent = "No content was found."
            }
            
            print("✅ Finished parsing")
            isLoading = false
            
        } catch {
            print("❌ Error in fetchArticleContent: \(error)")
            self.error = error
            isLoading = false
        }
    }
} 
