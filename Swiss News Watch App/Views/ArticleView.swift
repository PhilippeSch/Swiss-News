import SwiftUI
import SwiftSoup

struct ArticleView: View {
    let title: String
    let url: String
    @State private var articleContent: String = "Loading..."
    @State private var isLoading = true
    @State private var error: Error?
    
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
        .task {
            await fetchArticleContent()
        }
    }
    
    private func fetchArticleContent() async {
        do {
            print("📱 Loading article from: \(url)")
            guard let url = URL(string: url) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            
            let document = try SwiftSoup.parse(html)
            
            // Versuche verschiedene Selektoren für 20min und SRF
            let possibleSelectors = [
                "section.articlepage__article-content",  // SRF Selector
                "div.article-content",                   // Möglicher 20min Selector
                "article",                               // Generischer Artikel Selector
                ".article__body"                         // Alternativer 20min Selector
            ]
            
            var content = ""
            
            for selector in possibleSelectors {
                if let articleSection = try document.select(selector).first() {
                    
                    // Handle bullet point lists
                    let lists = try articleSection.select("ul")
                    for list in lists {
                        let items = try list.select("li")
                        for item in items {
                            let itemText = try item.text()
                            content += "• \(itemText)\n"
                        }
                        content += "\n"
                    }
                    
                    // Handle paragraphs
                    let paragraphs = try articleSection.select("p")
                    for paragraph in paragraphs {
                        let paragraphText = try paragraph.text()
                        if !paragraphText.isEmpty {
                            content += "\(paragraphText)\n\n"
                        }
                    }
                    
                    break // Beende die Suche, wenn Content gefunden wurde
                }
            }
            
            // Clean up multiple line breaks
            let cleanedContent = content.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            articleContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if articleContent.isEmpty {
                articleContent = "No content was found."
            }
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
} 
