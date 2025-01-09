import SwiftUI
import SwiftSoup

struct ArticleView: View {
    let title: String
    let url: String
    @State private var articleContent: String = ""
    @State private var isLoading = true
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss
    
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
                    HyphenatedTextView(text: articleContent)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
        }
        .navigationTitle("Artikel")
        .interactiveDismissDisabled(isLoading)
        .task {
            await fetchArticleContent()
        }
    }
    
    private func fetchArticleContent() async {
        do {
            guard let url = URL(string: url) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            
            let document = try SwiftSoup.parse(html)
            var content = ""
            
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
            
            if content.isEmpty {
                let possibleSelectors = [
                    "section.articlepage__article-content",
                    "div.article-content",
                    "article",
                    ".article__body"
                ]
                
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
                        
                        break
                    }
                }
            }
            
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
