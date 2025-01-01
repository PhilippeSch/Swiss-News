import SwiftUI
import WatchKit
import AuthenticationServices

struct NewsCategoryView: View {
    let title: String
    let newsItems: [NewsItem]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(newsItems) { item in
                    NewsItemView(item: item)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle(title)
    }
}

struct NewsItemView: View {
    let item: NewsItem
    @State private var webAuthSession: ASWebAuthenticationSession?
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        formatter.locale = Locale(identifier: "de_CH")
        return formatter
    }()
    
    private func getMobileURL(_ originalURL: String) -> URL? {
        let mobileURL = originalURL.replacingOccurrences(of: "www.srf.ch", with: "m.srf.ch")
        return URL(string: mobileURL)
    }
    
    private func openURL(_ url: URL) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: nil
        ) { _, error in
            if let error = error {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
        session.prefersEphemeralWebBrowserSession = true
        session.start()
        webAuthSession = session
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.headline)
            
            if let imageUrl = item.imageUrl {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure(_):
                        Image(systemName: "photo")
                            .imageScale(.large)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            Text(item.cleanDescription)
                .font(.body)
            
            HStack {
                Text(dateFormatter.string(from: item.pubDate))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button("Lesen") {
                    WKInterfaceDevice.current().play(.click)
                    if let url = getMobileURL(item.link) ?? URL(string: item.link) {
                        openURL(url)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.clear))
        .cornerRadius(12)
        .alert("Fehler", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
} 