// Mocks/MockFetchArticlesUseCase.swift
// Test double for FetchArticlesUseCaseProtocol.
// @unchecked Sendable: mutation is safe because tests run serially.

import Foundation
@testable import SpaceFlightNews

final class MockFetchArticlesUseCase: FetchArticlesUseCaseProtocol, @unchecked Sendable {

    // MARK: - Stubs

    var stubbedResult = ArticlePageResult(articles: [], nextPageURL: nil)
    var stubbedError: Error?

    // MARK: - Call tracking

    private(set) var callCount = 0
    private(set) var lastNextPageURL: String?
    private(set) var lastSearch: String?

    // MARK: - FetchArticlesUseCaseProtocol

    func execute(nextPageURL: String?, search: String?, limit: Int) async throws -> ArticlePageResult {
        callCount += 1
        lastNextPageURL = nextPageURL
        lastSearch = search
        if let error = stubbedError { throw error }
        return stubbedResult
    }
}
