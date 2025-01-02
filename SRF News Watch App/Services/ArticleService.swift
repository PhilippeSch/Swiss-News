import Foundation

@MainActor
class ArticleService: ObservableObject {
    private struct TokenResponse: Codable {
        let access_token: String
        let token_type: String
        let expires_in: Int
    }
    
    enum ArticleError: LocalizedError {
        case invalidURL
        case invalidResponse
        case networkError(String)
        case noContent
        case authenticationError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Ungültige URL"
            case .invalidResponse: return "Ungültige Antwort vom Server"
            case .networkError(let message): return message
            case .noContent: return "Kein Inhalt verfügbar"
            case .authenticationError: return "Authentifizierungsfehler"
            }
        }
    }
    
    private let credentials = "dWVSQUlRT2s0RXFIQzFBaHJTSmJlQmFwc2kwMlZIbmw6VUtWT0owMGRWVUdtdVByRQ==" //BASE64 hash
    private var accessToken: String?
    
    func getAccessToken() async throws -> String {
        if let existingToken = accessToken {
            return existingToken
        }
        
        let tokenUrl = "https://api.srgssr.ch/oauth/v1/accesstoken?grant_type=client_credentials"
        guard let url = URL(string: tokenUrl) else {
            throw ArticleError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw ArticleError.authenticationError
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            self.accessToken = tokenResponse.access_token
            return tokenResponse.access_token
        } catch {
            throw ArticleError.authenticationError
        }
    }
    
    func fetchArticleContent(from urlString: String, guid: String) async throws -> String {
        let token = try await getAccessToken()
        
        // Construct API URL with full GUID
        let apiUrlString = "https://api.srgssr.ch/srgssr-articles/v2/articles?publisher=SRF&limit=1&id=\(guid)"
        guard let apiUrl = URL(string: apiUrlString) else {
            throw ArticleError.invalidURL
        }
        
        var request = URLRequest(url: apiUrl)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ArticleError.invalidResponse
            }
            
            // Add status code to error message if not 200
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "No error details"
                throw ArticleError.networkError("Status: \(httpResponse.statusCode)\nURL: \(apiUrlString)\nDetails: \(errorMessage)")
            }
            
            let decoder = JSONDecoder()
            let articleResponse = try decoder.decode(ArticleResponse.self, from: data)
            
            guard let article = articleResponse.results.first,
                  let content = article.content,
                  !content.text.isEmpty else {
                throw ArticleError.noContent
            }
            
            return content.text.joined(separator: "\n\n")
        } catch let decodingError as DecodingError {
            throw ArticleError.networkError("Decoding error: \(decodingError.localizedDescription)")
        } catch {
            throw ArticleError.networkError("Error: \(error.localizedDescription)")
        }
    }
} 
