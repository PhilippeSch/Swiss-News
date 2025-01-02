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
                    ProgressView("Laden...")
                        .frame(maxWidth: .infinity, alignment: .center)
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
                    Text(articleContent)
                        .font(.footnote)
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
            guard let url = URL(string: url) else {
                throw URLError(.badURL)
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else {
                throw URLError(.cannotDecodeContentData)
            }
            
            let document = try SwiftSoup.parse(html)
            var content = ""
            
            if let articleSection = try document.select("section.articlepage__article-content").first() {
                // Handle bullet point lists
                let lists = try articleSection.select("ul.article-list")
                for list in lists {
                    let items = try list.select("li")
                    for item in items {
                        let itemText = try item.text()
                        content += "• \(itemText)\n"
                    }
                    content += "\n"
                }
                
                // Handle paragraphs, excluding those directly inside expandable boxes
                let paragraphs = try articleSection.select("p.article-paragraph")
                for paragraph in paragraphs {
                    // Check if the paragraph's parent is an expandable box
                    let parent = paragraph.parent()
                    if parent?.hasClass("expandable-box") != true {
                        let paragraphText = try paragraph.text()
                        content += "\(paragraphText)\n\n"
                    }
                }
                
                // Clean up multiple line breaks
                let cleanedContent = content.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
                articleContent = cleanedContent.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                articleContent = "No content was found."
            }
            
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
} 
