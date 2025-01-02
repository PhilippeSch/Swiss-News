import SwiftUI
import WatchKit
import AuthenticationServices

struct NewsCategoryView: View {
    let title: String
    let newsItems: [NewsItem]
    
    var body: some View {
        List {
            ForEach(newsItems) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    
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
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                    
                    HStack {
                        Text(dateFormatter.string(from: item.pubDate))
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        NavigationLink {
                            ArticleView(title: item.title, url: item.link, guid: item.guid)
                        } label: {
                            Text("Lesen")
                                .font(.system(size: 14))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.clear))
                .cornerRadius(12)
            }
        }
        .navigationTitle(title)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.dateFormat = "dd.MM.yy\nHH:mm"
        return formatter
    }()
} 
