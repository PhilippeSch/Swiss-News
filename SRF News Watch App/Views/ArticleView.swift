import SwiftUI

struct ArticleView: View {
    let title: String
    let url: String
    let guid: String
    @State private var isLoading = false
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
                    Text("Full article content will be available here.")
                        .font(.body)
                }
            }
            .padding()
        }
        .navigationTitle("Artikel")
    }
} 