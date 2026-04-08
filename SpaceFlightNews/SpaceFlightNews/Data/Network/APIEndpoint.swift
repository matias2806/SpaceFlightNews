// Data/Network/APIEndpoint.swift
// Typed enum that owns all knowledge of how to build a URLRequest.

import Foundation

enum APIEndpoint {

    // MARK: - Cases

    case articles(search: String?, limit: Int)
    case nextPage(url: URL)      // follows the API's "next" cursor URL verbatim
    case articleDetail(id: Int)

    // MARK: - Base

    private static let baseURL = URL(string: "https://api.spaceflightnewsapi.net/v4")!

    // MARK: - URLRequest builder

    func urlRequest() throws -> URLRequest {
        switch self {
        case .nextPage(let url):
            // The cursor URL is complete — use it directly without modification.
            return Self.baseRequest(for: url)

        default:
            guard var components = URLComponents(
                url: Self.baseURL.appendingPathComponent(path),
                resolvingAgainstBaseURL: false
            ) else {
                throw AppError.unknown
            }
            let items = queryItems
            if !items.isEmpty { components.queryItems = items }
            guard let url = components.url else { throw AppError.unknown }
            return Self.baseRequest(for: url)
        }
    }

    // MARK: - Private helpers

    private var path: String {
        switch self {
        case .articles:              return "articles"
        case .articleDetail(let id): return "articles/\(id)"
        case .nextPage:              return ""   // unused — handled above
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case .articles(let search, let limit):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            if let search, !search.trimmingCharacters(in: .whitespaces).isEmpty {
                items.append(URLQueryItem(name: "search", value: search))
            }
            return items

        case .articleDetail, .nextPage:
            return []
        }
    }

    private static func baseRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        return request
    }
}
