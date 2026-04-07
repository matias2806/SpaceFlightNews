// Domain/Models/Article.swift
// Core business entity. Immutable, type-safe, zero external dependencies.
// No Decodable — that's Data layer responsibility.

import Foundation

// Hashable required for NavigationStack's navigationDestination(for: Article.self).
struct Article: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let articleURL: URL
    let imageURL: URL?
    let newsSite: String
    let summary: String
    let publishedAt: Date
}
