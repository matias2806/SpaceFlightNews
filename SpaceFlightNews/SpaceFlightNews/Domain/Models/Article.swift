// Domain/Models/Article.swift
// Core business entity. Immutable, type-safe, zero external dependencies.
// No Decodable — that's Data layer responsibility.

import Foundation

struct Article: Identifiable, Equatable, Sendable {
    let id: Int
    let title: String
    let articleURL: URL
    let imageURL: URL?
    let newsSite: String
    let summary: String
    let publishedAt: Date
}
