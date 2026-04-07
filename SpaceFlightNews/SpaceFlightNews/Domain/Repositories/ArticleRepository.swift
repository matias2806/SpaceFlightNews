// Domain/Repositories/ArticleRepository.swift
// Protocol only. Domain owns the contract; Data provides the implementation.
// This boundary enables swapping implementations (e.g. cache, mock) without
// touching Domain or Presentation.

import Foundation

protocol ArticleRepository: Sendable {
    /// Fetch a page of articles, optionally filtered by search query.
    /// - Parameters:
    ///   - search: Optional full-text search string.
    ///   - limit: Number of items to fetch.
    ///   - offset: Pagination offset.
    func fetchArticles(search: String?, limit: Int, offset: Int) async throws -> [Article]

    /// Fetch a single article by its unique identifier.
    func fetchArticle(id: Int) async throws -> Article
}
