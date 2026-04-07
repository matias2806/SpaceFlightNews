// Data/DTOs/ArticleDTO.swift
// Decodable mirror of the Spaceflight News API v4 response.
// Intentionally dumb — no logic, no URL validation, no date parsing.
// All transformation happens in ArticleMapper.

import Foundation

/// Single article as returned by /v4/articles/{id} and inside /v4/articles results.
// Sendable conformance is implicit (struct with all-Sendable members).
// Explicit Sendable causes a compiler error with SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
// because the synthesized Decodable init becomes @MainActor-isolated and can't satisfy
// a Sendable type-parameter constraint.
struct ArticleDTO: Decodable {
    let id: Int
    let title: String
    let url: String
    let imageUrl: String?
    let newsSite: String
    let summary: String
    let publishedAt: String   // ISO8601 string — mapper converts to Date
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, url, summary
        case imageUrl    = "image_url"
        case newsSite    = "news_site"
        case publishedAt = "published_at"
        case updatedAt   = "updated_at"
    }
}

/// Paginated list response wrapper from /v4/articles.
struct ArticleListDTO: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [ArticleDTO]
}
