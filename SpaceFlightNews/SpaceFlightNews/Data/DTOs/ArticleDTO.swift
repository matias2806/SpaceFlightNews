// Data/DTOs/ArticleDTO.swift
// Decodable mirror of the Spaceflight News API v4 response.
// Intentionally dumb — no logic, no URL validation, no date parsing.
// All transformation happens in ArticleMapper.

import Foundation

struct ArticleDTO: Decodable {
    let id: Int
    let title: String
    let url: String
    let imageUrl: String?
    let newsSite: String
    let summary: String
    let publishedAt: String
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
