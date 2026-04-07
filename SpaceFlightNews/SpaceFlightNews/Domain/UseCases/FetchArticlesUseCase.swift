// Domain/UseCases/FetchArticlesUseCase.swift
// Encapsulates the "fetch paginated articles with optional search" operation.
// The protocol enables mock injection in unit tests without hitting the network.

import Foundation

protocol FetchArticlesUseCaseProtocol: Sendable {
    func execute(search: String?, limit: Int, offset: Int) async throws -> [Article]
}

final class FetchArticlesUseCase: FetchArticlesUseCaseProtocol {

    private let repository: any ArticleRepository

    init(repository: some ArticleRepository) {
        self.repository = repository
    }

    func execute(search: String?, limit: Int, offset: Int) async throws -> [Article] {
        try await repository.fetchArticles(search: search, limit: limit, offset: offset)
    }
}
