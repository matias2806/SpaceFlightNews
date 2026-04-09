// Mocks/MockArticleRepository.swift
// Test double for ArticleRepository protocol.
// @unchecked Sendable: mutation is safe because tests run serially.

import Foundation
@testable import SpaceFlightNews

final class MockArticleRepository: ArticleRepository, @unchecked Sendable {

    // MARK: - Stubs

    var stubbedPageResult = ArticlePageResult(articles: [], nextPageURL: nil)
    var stubbedError: Error?

    // MARK: - Call tracking

    private(set) var fetchArticlesCallCount = 0
    private(set) var fetchNextPageCallCount = 0
    private(set) var lastFetchNextPageURL: String?
    private(set) var lastSearchQuery: String?
    private(set) var lastLimit: Int?

    // MARK: - ArticleRepository

    func fetchArticles(search: String?, limit: Int) async throws -> ArticlePageResult {
        fetchArticlesCallCount += 1
        lastSearchQuery = search
        lastLimit = limit
        if let error = stubbedError { throw error }
        return stubbedPageResult
    }

    func fetchNextPage(url: String) async throws -> ArticlePageResult {
        fetchNextPageCallCount += 1
        lastFetchNextPageURL = url
        if let error = stubbedError { throw error }
        return stubbedPageResult
    }
}
