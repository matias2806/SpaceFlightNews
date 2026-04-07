// Data/Network/APIEndpoint.swift
// Typed enum that owns all knowledge of how to build a URLRequest.
// Adding a new endpoint = adding a case here, nothing else changes.

import Foundation

enum APIEndpoint {

    // MARK: - Cases

    case articles(search: String?, limit: Int, offset: Int)
    case articleDetail(id: Int)

    // MARK: - Base

    private static let baseURL = URL(string: "https://api.spaceflightnewsapi.net/v4")!

    // MARK: - URLRequest builder

    func urlRequest() throws -> URLRequest {
        guard var components = URLComponents(
            url: Self.baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw AppError.invalidEndpoint
        }

        let items = queryItems
        if !items.isEmpty { components.queryItems = items }

        guard let url = components.url else {
            throw AppError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        return request
    }

    // MARK: - Private helpers

    private var path: String {
        switch self {
        case .articles:
            return "articles"
        case .articleDetail(let id):
            return "articles/\(id)"
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case .articles(let search, let limit, let offset):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "limit",  value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ]
            if let search, !search.trimmingCharacters(in: .whitespaces).isEmpty {
                items.append(URLQueryItem(name: "search", value: search))
            }
            return items

        case .articleDetail:
            return []
        }
    }
}
