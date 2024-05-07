//
//  BookManager.swift
//  NBCBookStrore
//
//  Created by David Jang on 5/2/24.
//

import Foundation

enum APIError: Error {
    case badURL, badResponse, decodingError
}

class BookManager {
    
    static let shared = BookManager()
    private let baseURL = "https://dapi.kakao.com/v3/search/book"
    private let apiKey = "b604c80b13039541ac749305437fa35f"
    
    func fetchBooks(query: String, sort: String = "accuracy", page: Int = 1, size: Int = 10, target: String = "title") async throws -> SearchResponse {
        guard var components = URLComponents(string: baseURL) else {
            throw APIError.badURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "sort", value: sort),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "target", value: target)
        ]
        
        guard let url = components.url else {
            throw APIError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("KakaoAK \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.badResponse
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
            return decodedResponse
        } catch {
            throw APIError.decodingError
        }
    }
}
