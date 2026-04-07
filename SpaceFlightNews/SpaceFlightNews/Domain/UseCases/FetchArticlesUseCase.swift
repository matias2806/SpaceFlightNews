// Domain/UseCases/FetchArticlesUseCase.swift
// Decides whether to start fresh (offset 0) or follow the API cursor (nextPageURL).
// Centralising this decision here keeps the ViewModel unaware of URL details.

import Foundation

protocol FetchArticlesUseCaseProtocol: Sendable {
    /// - Parameters:
    ///   - nextPageURL: Pass nil for the first page; pass the previous result's
    ///     nextPageURL for subsequent pages. When non-nil, `search` and `limit`
    ///     are ignored — the cursor URL already encodes them.
    ///   - search: Optional title filter (used only on the first page call).
    ///   - limit: Page size (used only when nextPageURL is nil).
    func execute(nextPageURL: String?, search: String?, limit: Int) async throws -> ArticlePageResult
}

final class FetchArticlesUseCase: FetchArticlesUseCaseProtocol {

    private let repository: any ArticleRepository

    init(repository: some ArticleRepository) {
        self.repository = repository
    }

    func execute(nextPageURL: String?, search: String?, limit: Int) async throws -> ArticlePageResult {
        if let nextPageURL {
            return try await repository.fetchNextPage(url: nextPageURL)
        } else {
            return try await repository.fetchArticles(search: search, limit: limit)
        }
    }
}
